local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "vtsls",
    desc = [[LSP wrapper around TypeScript extension bundled with VSCode.]],
    homepage = "https://github.com/yioneko/vtsls",
    categories = { Pkg.Cat.LSP },
    languages = { Pkg.Lang.TypeScript, Pkg.Lang.JavaScript },
    install = npm.packages { "@vtsls/language-server" },
}
