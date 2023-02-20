local Pkg = require "mason-core.package"
local gem = require "mason-core.managers.gem"

return Pkg.new {
    name = "standardrb",
    desc = [[Ruby Style Guide, with linter and automatic code fixer]],
    homepage = "https://github.com/testdouble/standard/",
    languages = { Pkg.Lang.Ruby },
    categories = { Pkg.Cat.Formatter, Pkg.Cat.Linter },
    install = gem.packages { "standard", bin = { "standardrb" } },
}
