local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "html-lsp",
    desc = [[Language Server Protocol implementation for HTML.]],
    homepage = "https://github.com/microsoft/vscode-html-languageservice",
    languages = { Pkg.Lang.HTML },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "vscode-langservers-extracted", bin = { "vscode-html-language-server" } },
}
