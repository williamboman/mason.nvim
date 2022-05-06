local display = require "nvim-lsp-installer.ui.display"
local match = require "luassert.match"
local spy = require "luassert.spy"
local Ui = require "nvim-lsp-installer.ui"
local a = require "nvim-lsp-installer.core.async"

describe("ui", function()
    it("produces a correct tree", function()
        local function renderer(state)
            return Ui.CascadingStyleNode({ "INDENT" }, {
                Ui.When(not state.is_active, function()
                    return Ui.Text {
                        "I'm not active",
                        "Another line",
                    }
                end),
                Ui.When(state.is_active, function()
                    return Ui.Text {
                        "I'm active",
                        "Yet another line",
                    }
                end),
            })
        end

        assert.same({
            children = {
                {
                    type = "HL_TEXT",
                    lines = {
                        { { "I'm not active", "" } },
                        { { "Another line", "" } },
                    },
                },
                {
                    type = "NODE",
                    children = {},
                },
            },
            styles = { "INDENT" },
            type = "CASCADING_STYLE",
        }, renderer { is_active = false })

        assert.same({
            children = {
                {
                    type = "NODE",
                    children = {},
                },
                {
                    type = "HL_TEXT",
                    lines = {
                        { { "I'm active", "" } },
                        { { "Yet another line", "" } },
                    },
                },
            },
            styles = { "INDENT" },
            type = "CASCADING_STYLE",
        }, renderer { is_active = true })
    end)

    it("renders a tree correctly", function()
        local render_output = display._render_node(
            {
                win_width = 120,
            },
            Ui.CascadingStyleNode({ "INDENT" }, {
                Ui.Keybind("i", "INSTALL_SERVER", { "sumneko_lua" }, true),
                Ui.HlTextNode {
                    {
                        { "Hello World!", "MyHighlightGroup" },
                    },
                    {
                        { "Another Line", "Comment" },
                    },
                },
                Ui.HlTextNode {
                    {
                        { "Install something idk", "Stuff" },
                    },
                },
                Ui.Keybind("<CR>", "INSTALL_SERVER", { "tsserver" }, false),
                Ui.Text { "I'm a text node" },
            })
        )

        assert.same({
            highlights = {
                {
                    col_start = 2,
                    col_end = 14,
                    line = 0,
                    hl_group = "MyHighlightGroup",
                },
                {
                    col_start = 2,
                    col_end = 14,
                    line = 1,
                    hl_group = "Comment",
                },
                {
                    col_start = 2,
                    col_end = 23,
                    line = 2,
                    hl_group = "Stuff",
                },
            },
            lines = { "  Hello World!", "  Another Line", "  Install something idk", "  I'm a text node" },
            virt_texts = {},
            keybinds = {
                {
                    effect = "INSTALL_SERVER",
                    key = "i",
                    line = -1,
                    payload = { "sumneko_lua" },
                },
                {
                    effect = "INSTALL_SERVER",
                    key = "<CR>",
                    line = 3,
                    payload = { "tsserver" },
                },
            },
        }, render_output)
    end)
end)

describe("integration test", function()
    it(
        "calls vim APIs as expected during rendering",
        async_test(function()
            local window = display.new_view_only_win "test"

            window.view(function(state)
                return Ui.Node {
                    Ui.Keybind("U", "EFFECT", nil, true),
                    Ui.Text {
                        "Line number 1!",
                        state.text,
                    },
                    Ui.Keybind("R", "R_EFFECT", { state.text }),
                    Ui.HlTextNode {
                        {
                            { "My highlighted text", "MyHighlightGroup" },
                        },
                    },
                }
            end)

            local mutate_state = window.init { text = "Initial state" }

            window.open {
                effects = {
                    ["EFFECT"] = function() end,
                    ["R_EFFECT"] = function() end,
                },
                highlight_groups = {
                    "hi def MyHighlight gui=bold",
                },
            }

            local clear_namespace = spy.on(vim.api, "nvim_buf_clear_namespace")
            local buf_set_option = spy.on(vim.api, "nvim_buf_set_option")
            local win_set_option = spy.on(vim.api, "nvim_win_set_option")
            local set_lines = spy.on(vim.api, "nvim_buf_set_lines")
            local set_extmark = spy.on(vim.api, "nvim_buf_set_extmark")
            local add_highlight = spy.on(vim.api, "nvim_buf_add_highlight")
            local set_keymap = spy.on(vim.api, "nvim_buf_set_keymap")

            -- Initial window and buffer creation + initial render
            a.scheduler()

            assert.spy(win_set_option).was_called(8)
            assert.spy(win_set_option).was_called_with(match.is_number(), "number", false)
            assert.spy(win_set_option).was_called_with(match.is_number(), "relativenumber", false)
            assert.spy(win_set_option).was_called_with(match.is_number(), "wrap", false)
            assert.spy(win_set_option).was_called_with(match.is_number(), "spell", false)
            assert.spy(win_set_option).was_called_with(match.is_number(), "foldenable", false)
            assert.spy(win_set_option).was_called_with(match.is_number(), "signcolumn", "no")
            assert.spy(win_set_option).was_called_with(match.is_number(), "colorcolumn", "")
            assert.spy(win_set_option).was_called_with(match.is_number(), "cursorline", true)

            assert.spy(buf_set_option).was_called(9)
            assert.spy(buf_set_option).was_called_with(match.is_number(), "modifiable", false)
            assert.spy(buf_set_option).was_called_with(match.is_number(), "swapfile", false)
            assert.spy(buf_set_option).was_called_with(match.is_number(), "textwidth", 0)
            assert.spy(buf_set_option).was_called_with(match.is_number(), "buftype", "nofile")
            assert.spy(buf_set_option).was_called_with(match.is_number(), "bufhidden", "wipe")
            assert.spy(buf_set_option).was_called_with(match.is_number(), "buflisted", false)
            assert.spy(buf_set_option).was_called_with(match.is_number(), "filetype", "lsp-installer")

            assert.spy(set_lines).was_called(1)
            assert.spy(set_lines).was_called_with(
                match.is_number(),
                0,
                -1,
                false,
                { "Line number 1!", "Initial state", "My highlighted text" }
            )

            assert.spy(set_extmark).was_called(0)

            assert.spy(add_highlight).was_called(1)
            assert.spy(add_highlight).was_called_with(
                match.is_number(),
                match.is_number(),
                "MyHighlightGroup",
                2,
                0,
                19
            )

            assert.spy(set_keymap).was_called(2)
            assert.spy(set_keymap).was_called_with(
                match.is_number(),
                "n",
                "U",
                match.has_match [[<cmd>lua require%('nvim%-lsp%-installer%.ui%.display'%)%.dispatch_effect%(%d, "55"%)<cr>]],
                { nowait = true, silent = true, noremap = true }
            )
            assert.spy(set_keymap).was_called_with(
                match.is_number(),
                "n",
                "R",
                match.has_match [[<cmd>lua require%('nvim%-lsp%-installer%.ui%.display'%)%.dispatch_effect%(%d, "52"%)<cr>]],
                { nowait = true, silent = true, noremap = true }
            )

            assert.spy(clear_namespace).was_called(1)
            assert.spy(clear_namespace).was_called_with(match.is_number(), match.is_number(), 0, -1)

            mutate_state(function(state)
                state.text = "New state"
            end)

            assert.spy(set_lines).was_called(1)
            a.scheduler()
            assert.spy(set_lines).was_called(2)

            assert.spy(set_lines).was_called_with(
                match.is_number(),
                0,
                -1,
                false,
                { "Line number 1!", "New state", "My highlighted text" }
            )
        end)
    )
end)
