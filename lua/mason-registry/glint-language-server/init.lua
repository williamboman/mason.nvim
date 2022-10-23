local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "glint-language-server",
    desc = [[Glint Language server, for Glimmer-flavored JavaScript and TypeScript]],
    homepage = "https://typed-ember.gitbook.io/glint/",
    categories = { Pkg.Cat.LSP },
    languages = {
        Pkg.Lang.Handlebars,
        Pkg.Lang.Glimmer,
        Pkg.Lang["typescript.glimmer"],
        Pkg.Lang["javascript.glimmer"],
    },
    install = npm.packages { "@glint/core", "typescript", bin = { "glint", "glint-language-server" } },
}
