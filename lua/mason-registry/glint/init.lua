local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "glint",
    desc = [[Glint Language server, for Glimmer-flavored JavaScript and TypeScript]],
    homepage = "https://typed-ember.gitbook.io/glint/",
    categories = { Pkg.Cat.LSP },
    languages = {
        Pkg.Lang.Handlebars,
        Pkg.Lang.Glimmer,
        Pkg.Lang.TypeScript,
        Pkg.Lang.JavaScript,
    },
    install = npm.packages { "@glint/core", "typescript", bin = { "glint", "glint-language-server" } },
}
