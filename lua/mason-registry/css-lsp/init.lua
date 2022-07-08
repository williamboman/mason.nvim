local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "css-lsp",
    desc = [[Language Server Protocol implementation for CSS, SCSS & LESS.]],
    homepage = "https://github.com/microsoft/vscode-css-languageservice",
    languages = { Pkg.Lang.CSS, Pkg.Lang.SCSS, Pkg.Lang.LESS },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "vscode-langservers-extracted", bin = { "vscode-css-language-server" } },
}
