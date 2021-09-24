local Ui = require "nvim-lsp-installer.ui"
local log = require "nvim-lsp-installer.log"
local process = require "nvim-lsp-installer.process"
local state = require "nvim-lsp-installer.ui.state"

local M = {}

local redraw_by_winnr = {}

function _G.lsp_install_redraw(winnr)
    local fn = redraw_by_winnr[winnr]
    if fn then
        fn()
    end
end

local function get_styles(line, render_context)
    local indentation = 0

    for i = 1, #render_context.applied_block_styles do
        local styles = render_context.applied_block_styles[i]
        for j = 1, #styles do
            local style = styles[j]
            if style == Ui.CascadingStyle.INDENT then
                indentation = indentation + 2
            elseif style == Ui.CascadingStyle.CENTERED then
                local padding = math.floor((render_context.context.win_width - #line) / 2)
                indentation = math.max(0, padding) -- CENTERED overrides any already applied indentation
            end
        end
    end

    return {
        indentation = indentation,
    }
end

local function render_node(context, node, _render_context, _output)
    local render_context = _render_context or {
        context = context,
        applied_block_styles = {},
    }
    local output = _output or {
        lines = {},
        virt_texts = {},
        highlights = {},
    }

    if node.type == Ui.NodeType.VIRTUAL_TEXT then
        output.virt_texts[#output.virt_texts + 1] = {
            line = #output.lines - 1,
            content = node.virt_text,
        }
    elseif node.type == Ui.NodeType.HL_TEXT then
        for i = 1, #node.lines do
            local line = node.lines[i]
            local line_highlights = {}
            local full_line = ""
            for j = 1, #line do
                local span = line[j]
                local content, hl_group = span[1], span[2]
                local col_start = #full_line
                full_line = full_line .. content
                line_highlights[#line_highlights + 1] = {
                    hl_group = hl_group,
                    line = #output.lines,
                    col_start = col_start,
                    col_end = col_start + #content,
                }
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
    elseif node.type == Ui.NodeType.NODE or node.type == Ui.NodeType.CASCADING_STYLE then
        if node.type == Ui.NodeType.CASCADING_STYLE then
            render_context.applied_block_styles[#render_context.applied_block_styles + 1] = node.styles
        end
        for i = 1, #node.children do
            render_node(context, node.children[i], render_context, output)
        end
        if node.type == Ui.NodeType.CASCADING_STYLE then
            render_context.applied_block_styles[#render_context.applied_block_styles] = nil
        end
    end

    return output
end

function M.new_view_only_win(name)
    local namespace = vim.api.nvim_create_namespace(("lsp_installer_%s"):format(name))
    local buf, renderer, mutate_state, get_state, unsubscribe
    local has_initiated = false

    local function open(opts)
        opts = opts or {}
        local win_width, highlight_groups = opts.win_width, opts.highlight_groups

        if win_width then
            vim.cmd(("%dvnew"):format(win_width))
        else
            vim.cmd [[vnew]]
        end

        local win = vim.api.nvim_get_current_win()
        buf = vim.api.nvim_get_current_buf()

        vim.api.nvim_buf_set_option(buf, "modifiable", false)
        vim.api.nvim_buf_set_option(buf, "swapfile", false)
        vim.api.nvim_buf_set_option(buf, "textwidth", 0)
        vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
        vim.api.nvim_buf_set_option(buf, "buflisted", false)
        vim.api.nvim_buf_set_option(buf, "filetype", "lsp-installer")

        vim.api.nvim_win_set_option(win, "wrap", false)
        vim.api.nvim_win_set_option(win, "spell", false)
        vim.api.nvim_win_set_option(win, "number", false)
        vim.api.nvim_win_set_option(win, "relativenumber", false)
        vim.api.nvim_win_set_option(win, "foldenable", false)
        vim.api.nvim_win_set_option(win, "signcolumn", "no")
        vim.api.nvim_win_set_option(win, "colorcolumn", "")

        vim.cmd [[ syntax clear ]]

        for _, redraw_event in ipairs { "WinEnter", "WinLeave", "VimResized" } do
            vim.cmd(("autocmd %s <buffer> call v:lua.lsp_install_redraw(%d)"):format(redraw_event, win))
        end

        vim.api.nvim_buf_set_keymap(buf, "n", "<esc>", "<cmd>bd<CR>", { noremap = true })
        vim.lsp.util.close_preview_autocmd({ "BufHidden", "BufLeave" }, win)

        if highlight_groups then
            for i = 1, #highlight_groups do
                vim.cmd(highlight_groups[i])
            end
        end

        return win
    end

    local draw = process.debounced(function(view)
        local win = vim.fn.win_findbuf(buf)[1]
        if not win or not vim.api.nvim_buf_is_valid(buf) then
            -- the window has been closed or the buffer is somehow no longer valid
            unsubscribe(true)
            return log.debug { "Buffer or window is no longer valid", name, win, buf }
        end

        local win_width = vim.api.nvim_win_get_width(win)
        local context = {
            win_width = win_width,
        }
        local output = render_node(context, view)
        local lines, virt_texts, highlights = output.lines, output.virt_texts, output.highlights

        vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
        vim.api.nvim_buf_set_option(buf, "modifiable", true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
        for i = 1, #virt_texts do
            local virt_text = virt_texts[i]
            vim.api.nvim_buf_set_extmark(buf, namespace, virt_text.line, 0, {
                virt_text = virt_text.content,
            })
        end
        for i = 1, #highlights do
            local highlight = highlights[i]
            vim.api.nvim_buf_add_highlight(
                buf,
                namespace,
                highlight.hl_group,
                highlight.line,
                highlight.col_start,
                highlight.col_end
            )
        end
    end)

    return {
        view = function(x)
            renderer = x
        end,
        init = function(initial_state)
            assert(renderer ~= nil, "No view function has been registered. Call .view() before .init().")
            has_initiated = true

            mutate_state, get_state, unsubscribe = state.create_state_container(initial_state, function(new_state)
                draw(renderer(new_state))
            end)

            return mutate_state, get_state
        end,
        open = vim.schedule_wrap(function(opts)
            log.debug { "opening window" }
            assert(has_initiated, "Display has not been initiated, cannot open.")
            local win = vim.fn.win_findbuf(buf)[1]
            if win and vim.api.nvim_win_is_valid(win) then
                return
            end
            unsubscribe(false)
            local opened_win = open(opts)
            draw(renderer(get_state()))
            redraw_by_winnr[opened_win] = function()
                draw(renderer(get_state()))
            end
        end),
        -- This is probably not needed.
        -- destroy = vim.schedule_wrap(function()
        --     assert(has_initiated, "Display has not been initiated, cannot destroy.")
        --     TODO: what happens with the state container, etc?
        --     unsubscribe(true)
        --     redraw_by_winnr[win] = nil
        --     if win then
        --         vim.api.nvim_win_close(win, true)
        --     end
        -- end),
    }
end

return M
