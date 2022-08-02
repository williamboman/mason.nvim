local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "xo",
    desc = [[JavaScript/TypeScript linter (ESLint wrapper) with great defaults]],
    homepage = "https://github.com/xojs/xo",
    languages = {
        Pkg.Lang.JavaScript,
        Pkg.Lang.TypeScript,
    },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "xo", bin = { "xo" } },
}
