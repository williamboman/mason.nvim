local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "dot-language-server",
    desc = [[A language server for the DOT language]],
    homepage = "https://github.com/nikeee/dot-language-server",
    languages = { Pkg.Lang.DOT },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "dot-language-server", bin = { "dot-language-server" } },
}
