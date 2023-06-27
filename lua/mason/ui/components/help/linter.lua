local Ui = require "mason-core.ui"
local p = require "mason.ui.palette"

---@param state InstallerUiState
return function(state)
    return Ui.HlTextNode {
        {
            p.Bold "What is a linter?",
        },
        { p.none "A linter is a static code analysis tool used to provide diagnostics around" },
        { p.none "programming errors, bugs, stylistic errors and suspicious constructs." },
        { p.none "Linters can be executed as a standalone program in a terminal, where it" },
        { p.none "usually expects one or more input files to lint. There are also Neovim plugins" },
        { p.none "that integrate these diagnostics inside the editor." },
    }
end
