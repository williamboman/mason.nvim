local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "jqls",
    desc = _.dedent [[
        jqls is a language server for the jq language, developed by Matthias Wadman. It provides
        IDE features to any LSP-compatible editor.
    ]],
    homepage = "https://github.com/wader/jq-lsp",
    languages = { Pkg.Lang.Jq },
    categories = { Pkg.Cat.LSP },
    install = go.packages { "github.com/wader/jq-lsp", bin = { "jq-lsp" } },
}
