local Ui = require "mason-core.ui"
local p = require "mason.ui.palette"

---@param state InstallerUiState
return function(state)
    return Ui.HlTextNode {
        {
            p.Bold "What is LSP?",
        },
        {
            p.none "The ",
            p.highlight_secondary "L",
            p.none "anguage ",
            p.highlight_secondary "S",
            p.none "erver ",
            p.highlight_secondary "P",
            p.none "rotocol defines the protocol used between an",
        },
        {
            p.none "editor or IDE and a language server that provides language features",
        },
        {
            p.none "like auto complete, go to definition, find all references etc.",
        },
        {},
        {
            p.none "The term ",
            p.highlight_secondary "LSP",
            p.none " is often used to reference a server implementation of",
        },
        { p.none "the LSP protocol." },
        {},
        { p.none "For more information, see:" },
        { p.none " - https://microsoft.github.io/language-server-protocol/" },
        { p.none " - ", p.highlight ":help lsp" },
    }
end
