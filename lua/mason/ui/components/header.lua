local Ui = require "mason-core.ui"
local p = require "mason.ui.palette"

---@param state InstallerUiState
return function(state)
    return Ui.CascadingStyleNode({ "CENTERED" }, {
        Ui.HlTextNode {
            Ui.When(state.view.is_showing_help, {
                p.none "             ",
                p.header_secondary(" " .. state.header.title_prefix .. " mason.nvim "),
                p.Comment " alpha branch",
                p.none((" "):rep(#state.header.title_prefix + 1)),
            }, {
                p.none "             ",
                p.header " mason.nvim ",
                p.Comment " alpha branch",
            }),
            Ui.When(
                state.view.is_showing_help,
                { p.none "        press ", p.highlight_secondary "?", p.none " for package list" },
                { p.none "press ", p.highlight "?", p.none " for help" }
            ),
            { p.Comment "https://github.com/williamboman/mason.nvim" },
            {
                p.Comment "Give usage feedback: https://github.com/williamboman/mason.nvim/discussions/new?category=ideas",
            },
        },
    })
end
