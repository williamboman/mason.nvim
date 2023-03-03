local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pyflakes",
    desc = [[A simple program which checks Python source files for errors.]],
    homepage = "https://pypi.org/project/pyflakes/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pyflakes", bin = { "pyflakes" } },
}
