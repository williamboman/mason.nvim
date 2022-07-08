local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "eslint_d",
    desc = [[Makes eslint the fastest linter on the planet]],
    homepage = "https://github.com/mantoni/eslint_d.js/",
    languages = { Pkg.Lang.TypeScript, Pkg.Lang.JavaScript },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "eslint_d", bin = { "eslint_d" } },
}
