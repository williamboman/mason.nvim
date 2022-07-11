local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pylint",
    desc = [[Pylint is a static code analyser for Python 2 or 3]],
    homepage = "https://pypi.org/project/pylint/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pylint", bin = { "pylint" } },
}
