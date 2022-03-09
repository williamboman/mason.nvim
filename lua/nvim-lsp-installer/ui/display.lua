local log = require "nvim-lsp-installer.log"
local process = require "nvim-lsp-installer.process"
local state = require "nvim-lsp-installer.ui.state"

local M = {}

local function from_hex(str)
    return (str:gsub("..", function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

local function to_hex(str)
    return (str:gsub(".", function(c)
        return string.format("%02X", string.byte(c))
    end))
end

---@param line string
---@param render_context RenderContext
local function get_styles(line, render_context)
    local indentation = 0

    for i = 1, #render_context.applied_block_styles do
        local styles = render_context.applied_block_styles[i]
        for j = 1, #styles do
            local style = styles[j]
            if style == "INDENT" then
                indentation = indentation + 2
            elseif style == "CENTERED" then
                local padding = math.floor((render_context.viewport_context.win_width - #line) / 2)
                indentation = math.max(0, padding) -- CENTERED overrides any already applied indentation
            end
        end
    end

    return {
        indentation = indentation,
    }
end

---@param viewport_context ViewportContext
---@param node INode
---@param _render_context RenderContext|nil
---@param _output RenderOutput|nil
local function render_node(viewport_context, node, _render_context, _output)
    ---@class RenderContext
    ---@field viewport_context ViewportContext
    ---@field applied_block_styles CascadingStyle[]
    local render_context = _render_context
        or {
            viewport_context = viewport_context,
            applied_block_styles = {},
        }
    ---@class RenderHighlight
    ---@field hl_group string
    ---@field line number
    ---@field col_start number
    ---@field col_end number

    ---@class RenderKeybind
    ---@field line number
    ---@field key string
    ---@field effect string
    ---@field payload any

    ---@class RenderOutput
    ---@field lines string[] @The buffer lines.
    ---@field virt_texts string[][] @List of (text, highlight) tuples.
    ---@field highlights RenderHighlight[]
    ---@field keybinds RenderKeybind[]
    local output = _output
        or {
            lines = {},
            virt_texts = {},
            highlights = {},
            keybinds = {},
        }

    if node.type == "VIRTUAL_TEXT" then
        output.virt_texts[#output.virt_texts + 1] = {
            line = #output.lines - 1,
            content = node.virt_text,
        }
    elseif node.type == "HL_TEXT" then
        for i = 1, #node.lines do
            local line = node.lines[i]
            local line_highlights = {}
            local full_line = ""
            for j = 1, #line do
                local span = line[j]
                local content, hl_group = span[1], span[2]
                local col_start = #full_line
                full_line = full_line .. content
                if hl_group ~= "" then
                    line_highlights[#line_highlights + 1] = {
                        hl_group = hl_group,
                        line = #output.lines,
                        col_start = col_start,
                        col_end = col_start + #content,
                    }
                end
            end

            local active_styles = get_styles(full_line, render_context)

            -- apply indentation
            full_line = (" "):rep(active_styles.indentation) .. full_line
            for j = 1, #line_highlights do
                local highlight = line_highlights[j]
                highlight.col_start = highlight.col_start + active_styles.indentation
                highlight.col_end = highlight.col_end + active_styles.indentation
                output.highlights[#output.highlights + 1] = highlight
            end

            output.lines[#output.lines + 1] = full_line
        end
    elseif node.type == "NODE" or node.type == "CASCADING_STYLE" then
        if node.type == "CASCADING_STYLE" then
            render_context.applied_block_styles[#render_context.applied_block_styles + 1] = node.styles
        end
        for i = 1, #node.children do
            render_node(viewport_context, node.children[i], render_context, output)
        end
        if node.type == "CASCADING_STYLE" then
            render_context.applied_block_styles[#render_context.applied_block_styles] = nil
        end
    elseif node.type == "KEYBIND_HANDLER" then
        output.keybinds[#output.keybinds + 1] = {
            line = node.is_global and -1 or #output.lines,
            key = node.key,
            effect = node.effect,
            payload = node.payload,
        }
    end

    return output
end

-- exported for tests
M._render_node = render_node

---@param sizes_only boolean @Whether to only return properties that control the window size.
local function create_popup_window_opts(sizes_only)
    local win_height = vim.o.lines - vim.o.cmdheight - 2 -- Add margin for status and buffer line
    local win_width = vim.o.columns
    local height = math.floor(win_height * 0.9)
    local width = math.floor(win_width * 0.8)
    local popup_layout = {
        height = height,
        width = width,
        row = math.floor((win_height - height) / 2),
        col = math.floor((win_width - width) / 2),
        relative = "editor",
        style = "minimal",
    }

    if not sizes_only then
        popup_layout.border = "rounded"
    end

    return popup_layout
end

local registered_effect_handlers_by_bufnr = {}
local active_keybinds_by_bufnr = {}
local registered_keymaps_by_bufnr = {}
local redraw_by_win_id = {}

---@param bufnr number
---@param line number
---@param key string
local function call_effect_handler(bufnr, line, key)
    local line_keybinds = active_keybinds_by_bufnr[bufnr][line]
    if line_keybinds then
        local keybind = line_keybinds[key]
        if keybind then
            local effect_handler = registered_effect_handlers_by_bufnr[bufnr][keybind.effect]
            if effect_handler then
                log.fmt_trace("Calling handler for effect %s on line %d for key %s", keybind.effect, line, key)
                effect_handler { payload = keybind.payload }
                return true
            end
        end
    end
    return false
end

M.dispatch_effect = function(bufnr, hex_key)
    local key = from_hex(hex_key)
    local line = vim.api.nvim_win_get_cursor(0)[1]
    log.fmt_trace("Dispatching effect on line %d, key %s, bufnr %s", line, key, bufnr)
    call_effect_handler(bufnr, line, key) -- line keybinds
    call_effect_handler(bufnr, -1, key) -- global keybinds
end

function M.redraw_win(win_id)
    local fn = redraw_by_win_id[win_id]
    if fn then
        fn()
    end
end

function M.delete_win_buf(win_id, bufnr)
    -- We queue the win_buf to be deleted in a schedule call, otherwise when used with folke/which-key (and
    -- set timeoutlen=0) we run into a weird segfault.
    -- It should probably be unnecessary once https://github.com/neovim/neovim/issues/15548 is resolved
    vim.schedule(function()
        if win_id and vim.api.nvim_win_is_valid(win_id) then
            log.trace "Deleting window"
            vim.api.nvim_win_close(win_id, true)
        end
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
            log.trace "Deleting buffer"
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
        if redraw_by_win_id[win_id] then
            redraw_by_win_id[win_id] = nil
        end
        if active_keybinds_by_bufnr[bufnr] then
            active_keybinds_by_bufnr[bufnr] = nil
        end
        if registered_effect_handlers_by_bufnr[bufnr] then
            registered_effect_handlers_by_bufnr[bufnr] = nil
        end
        if registered_keymaps_by_bufnr[bufnr] then
            registered_keymaps_by_bufnr[bufnr] = nil
        end
    end)
end

function M.new_view_only_win(name)
    local namespace = vim.api.nvim_create_namespace(("lsp_installer_%s"):format(name))
    local bufnr, renderer, mutate_state, get_state, unsubscribe, win_id
    local has_initiated = false

    ---@param opts DisplayOpenOpts
    local function open(opts)
        opts = opts or {}
        local highlight_groups = opts.highlight_groups
        bufnr = vim.api.nvim_create_buf(false, true)
        win_id = vim.api.nvim_open_win(bufnr, true, create_popup_window_opts(false))

        registered_effect_handlers_by_bufnr[bufnr] = {}
        active_keybinds_by_bufnr[bufnr] = {}
        registered_keymaps_by_bufnr[bufnr] = {}

        local buf_opts = {
            modifiable = false,
            swapfile = false,
            textwidth = 0,
            buftype = "nofile",
            bufhidden = "wipe",
            buflisted = false,
            filetype = "lsp-installer",
        }

        local win_opts = {
            number = false,
            relativenumber = false,
            wrap = false,
            spell = false,
            foldenable = false,
            signcolumn = "no",
            colorcolumn = "",
            cursorline = true,
        }

        -- window options
        for key, value in pairs(win_opts) do
            vim.api.nvim_win_set_option(win_id, key, value)
        end

        -- buffer options
        for key, value in pairs(buf_opts) do
            vim.api.nvim_buf_set_option(bufnr, key, value)
        end

        vim.cmd [[ syntax clear ]]

        local resize_autocmd = (
            "autocmd VimResized <buffer> lua require('nvim-lsp-installer.ui.display').redraw_win(%d)"
        ):format(win_id)
        local autoclose_autocmd = (
            "autocmd WinLeave,BufHidden,BufLeave <buffer> ++once lua require('nvim-lsp-installer.ui.display').delete_win_buf(%d, %d)"
        ):format(win_id, bufnr)

        vim.cmd(([[
            augroup LspInstallerWindow
                autocmd!
                %s
                %s
            augroup END
        ]]):format(resize_autocmd, autoclose_autocmd))

        if highlight_groups then
            for i = 1, #highlight_groups do
                vim.cmd(highlight_groups[i])
            end
        end

        return win_id
    end

    local draw = function(view)
        local win_valid = win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
        local buf_valid = bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
        log.fmt_trace("got bufnr=%s", bufnr)
        log.fmt_trace("got win_id=%s", win_id)

        if not win_valid or not buf_valid then
            -- the window has been closed or the buffer is somehow no longer valid
            unsubscribe(true)
            log.trace("Buffer or window is no longer valid", win_id, bufnr)
            return
        end

        local win_width = vim.api.nvim_win_get_width(win_id)
        ---@class ViewportContext
        local viewport_context = {
            win_width = win_width,
        }
        local output = render_node(viewport_context, view)
        local lines, virt_texts, highlights, keybinds =
            output.lines, output.virt_texts, output.highlights, output.keybinds

        -- set line contents
        vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
        vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

        for i = 1, #virt_texts do
            local virt_text = virt_texts[i]
            vim.api.nvim_buf_set_extmark(bufnr, namespace, virt_text.line, 0, {
                virt_text = virt_text.content,
            })
        end

        -- set highlights
        for i = 1, #highlights do
            local highlight = highlights[i]
            vim.api.nvim_buf_add_highlight(
                bufnr,
                namespace,
                highlight.hl_group,
                highlight.line,
                highlight.col_start,
                highlight.col_end
            )
        end

        -- set keybinds
        local buf_keybinds = {}
        active_keybinds_by_bufnr[bufnr] = buf_keybinds
        for i = 1, #keybinds do
            local keybind = keybinds[i]
            if not buf_keybinds[keybind.line] then
                buf_keybinds[keybind.line] = {}
            end
            buf_keybinds[keybind.line][keybind.key] = keybind
            if not registered_keymaps_by_bufnr[bufnr][keybind.key] then
                vim.api.nvim_buf_set_keymap(
                    bufnr,
                    "n",
                    keybind.key,
                    ("<cmd>lua require('nvim-lsp-installer.ui.display').dispatch_effect(%d, %q)<cr>"):format(
                        bufnr,
                        -- We transfer the keybinding as hex to avoid issues with (neo)vim interpreting the key as a
                        -- literal input to the command. For example, "<CR>" would cause vim to issue an actual carriage
                        -- return - even if it's quoted as a string.
                        to_hex(keybind.key)
                    ),
                    { nowait = true, silent = true, noremap = true }
                )
            end
        end
    end

    return {
        ---@param _renderer fun(state: table): table
        view = function(_renderer)
            renderer = _renderer
        end,
        ---@generic T : table
        ---@param initial_state T
        ---@return fun(mutate_fn: fun(current_state: T)), fun(): T
        init = function(initial_state)
            assert(renderer ~= nil, "No view function has been registered. Call .view() before .init().")
            has_initiated = true

            mutate_state, get_state, unsubscribe = state.create_state_container(
                initial_state,
                process.debounced(function(new_state)
                    draw(renderer(new_state))
                end)
            )

            -- we don't need to subscribe to state changes until the window is actually opened
            unsubscribe(true)

            return mutate_state, get_state
        end,
        ---@alias DisplayOpenOpts {effects: table<string, fun()>, highlight_groups: string[]|nil}
        ---@type fun(opts: DisplayOpenOpts)
        open = vim.schedule_wrap(function(opts)
            log.trace "Opening window"
            assert(has_initiated, "Display has not been initiated, cannot open.")
            if win_id and vim.api.nvim_win_is_valid(win_id) then
                -- window is already open
                return
            end
            unsubscribe(false)
            local opened_win_id = open(opts)
            draw(renderer(get_state()))
            registered_effect_handlers_by_bufnr[bufnr] = opts.effects
            redraw_by_win_id[opened_win_id] = function()
                if vim.api.nvim_win_is_valid(opened_win_id) then
                    draw(renderer(get_state()))
                    vim.api.nvim_win_set_config(opened_win_id, create_popup_window_opts(true))
                end
            end
        end),
        ---@type fun()
        close = vim.schedule_wrap(function()
            assert(has_initiated, "Display has not been initiated, cannot close.")
            unsubscribe(true)
            M.delete_win_buf(win_id, bufnr)
        end),
        ---@param pos number[] @(row, col) tuple
        set_cursor = function(pos)
            assert(win_id ~= nil, "Window has not been opened, cannot set cursor.")
            return vim.api.nvim_win_set_cursor(win_id, pos)
        end,
        ---@return number[] @(row, col) tuple
        get_cursor = function()
            assert(win_id ~= nil, "Window has not been opened, cannot get cursor.")
            return vim.api.nvim_win_get_cursor(win_id)
        end,
    }
end

return M
