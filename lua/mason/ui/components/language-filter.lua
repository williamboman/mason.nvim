local Ui = require "mason-core.ui"
local p = require "mason.ui.palette"
local settings = require "mason.settings"

---@param state InstallerUiState
return function(state)
    return Ui.CascadingStyleNode({ "INDENT" }, {
        Ui.When(state.view.language_filter, function()
            return Ui.Node {
                Ui.EmptyLine(),
                Ui.HlTextNode {
                    {
                        p.Bold "Language Filter: ",
                        p.highlight(state.view.language_filter),
                        p.Comment " press <Esc> to clear",
                    },
                },
            }
        end),
        Ui.When(not state.view.language_filter, function()
            return Ui.Node {
                Ui.EmptyLine(),
                Ui.HlTextNode {
                    {
                        p.Bold "Language Filter:",
                        p.Comment(
                            (" press %s to apply filter"):format(settings.current.ui.keymaps.apply_language_filter)
                        ),
                    },
                },
            }
        end),
    })
end
