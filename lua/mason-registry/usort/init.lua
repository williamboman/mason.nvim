local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "usort",
    desc = [[Safe, minimal import sorting for Python projects.]],
    homepage = "https://usort.readthedocs.io/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "usort", bin = { "usort" } },
}
