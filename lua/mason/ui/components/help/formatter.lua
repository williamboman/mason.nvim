local Ui = require "mason-core.ui"
local p = require "mason.ui.palette"

---@param state InstallerUiState
return function(state)
    return Ui.HlTextNode {
        {
            p.Bold "What is a formatter?",
        },
        { p.none "A code formatter is a tool that reformats code to fit a certain" },
        { p.none "formatting convention. This usually entails things like adjusting" },
        { p.none "indentation, breaking long lines into smaller lines, adding or" },
        { p.none "removing whitespaces. Formatting rules are often included as a" },
        { p.none "separate configuration file within the project." },
    }
end
