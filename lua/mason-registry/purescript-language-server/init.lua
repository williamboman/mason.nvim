local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "purescript-language-server",
    desc = _.dedent [[
        Node-based Language Server Protocol server for PureScript based on the PureScript IDE server (aka psc-ide / purs
        ide server). Used as the vscode plugin backend but should be compatible with other Language Server Client
        implementations.
    ]],
    languages = { Pkg.Lang.PureScript },
    categories = { Pkg.Cat.LSP },
    homepage = "https://github.com/nwolverson/purescript-language-server",
    install = npm.packages { "purescript-language-server", bin = { "purescript-language-server" } },
}
