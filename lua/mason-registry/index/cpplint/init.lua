local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "cpplint",
    desc = [[Cpplint is a command-line tool to check C/C++ files for style issues following Google's C++ style guide]],
    homepage = "https://pypi.org/project/cpplint/",
    languages = { Pkg.Lang.C, Pkg.Lang["C++"] },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "cpplint", bin = { "cpplint" } },
}
