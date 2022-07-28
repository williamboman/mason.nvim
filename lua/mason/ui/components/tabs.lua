local Package = require "mason-core.package"
local Ui = require "mason-core.ui"
local p = require "mason.ui.palette"

---@param text string
---@param index integer
---@param is_active boolean
---@param use_secondary_highlight boolean
local function create_tab_span(text, index, is_active, use_secondary_highlight)
    local highlight_block = use_secondary_highlight and p.highlight_block_bold_secondary or p.highlight_block_bold

    if is_active then
        return {
            highlight_block " ",
            highlight_block("(" .. index .. ")"),
            highlight_block(" " .. text .. " "),
            p.none " ",
        }
    else
        return {
            p.muted_block " ",
            p.muted_block("(" .. index .. ")"),
            p.muted_block(" " .. text .. " "),
            p.none " ",
        }
    end
end

---@param state InstallerUiState
return function(state)
    local tabs = {}
    for i, text in ipairs { "All", Package.Cat.LSP, Package.Cat.DAP, Package.Cat.Linter, Package.Cat.Formatter } do
        vim.list_extend(tabs, create_tab_span(text, i, state.view.current == text, state.view.is_showing_help))
    end
    return Ui.CascadingStyleNode({ "INDENT" }, {
        Ui.HlTextNode { tabs },
        Ui.StickyCursor { id = "tabs" },
    })
end
