local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "json-lsp",
    desc = [[Language Server Protocol implementation for JSON.]],
    homepage = "https://github.com/microsoft/vscode-json-languageservice",
    languages = { Pkg.Lang.JSON },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "vscode-langservers-extracted", bin = { "vscode-json-language-server" } },
}
