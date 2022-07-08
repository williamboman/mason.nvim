local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "stylelint-lsp",
    desc = [[A stylelint Language Server]],
    homepage = "https://github.com/bmatcuk/stylelint-lsp",
    languages = { Pkg.Lang.Stylelint },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "stylelint-lsp", bin = { "stylelint-lsp" } },
}
