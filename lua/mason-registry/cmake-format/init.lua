local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "cmake-format",
    desc = [[Source code formatter for cmake listfiles]],
    homepage = "https://pypi.org/project/cmakelang/",
    languages = { Pkg.Lang.CMake },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "cmakelang", bin = { "cmake-format" } },
}
