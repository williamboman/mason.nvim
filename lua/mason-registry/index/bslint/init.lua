local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "bslint",
    desc = [[A brighterscript CLI tool to lint your code without compiling your project.]],
    homepage = "https://github.com/rokucommunity/bslint",
    languages = { Pkg.Lang.BrighterScript },
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "@rokucommunity/bslint", bin = { "bslint" } },
}
