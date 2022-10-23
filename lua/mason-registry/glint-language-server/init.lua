local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "glint-language-server",
    desc = [[Glint Language server, for Glimmer-flavored JavaScript and TypeScript]],
    homepage = "https://github.com/typed-ember/glint/tree/main/packages/core",
    categories = { Pkg.Cat.LSP },
    languages = {
        Pkg.Lang.Handlebars,
        Pkg.Lang.Glimmer,
        Pkg.Lang["glimmer.typescript"],
        Pkg.Lang["glimmer.javascript"]
    },
    install = npm.packages { "@glint/core", "typescript", bin = { "glint-language-server" } },
}
