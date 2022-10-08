local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pylama",
    desc = [[Code audit tool for Python.]],
    homepage = "https://klen.github.io/pylama/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pylama[all]", bin = { "pylama" } },
}
