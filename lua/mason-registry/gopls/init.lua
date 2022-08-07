local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local go = require "mason-core.managers.go"

return Pkg.new {
    name = "gopls",
    desc = _.dedent [[
        gopls (pronounced "Go please") is the official Go language server developed by the Go team. It provides IDE
        features to any LSP-compatible editor.
    ]],
    homepage = "https://pkg.go.dev/golang.org/x/tools/gopls",
    languages = { Pkg.Lang.Go },
    categories = { Pkg.Cat.LSP },
    install = go.packages { "golang.org/x/tools/gopls", bin = { "gopls" } },
}
