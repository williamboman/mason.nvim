local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "black",
    desc = [[Black, the uncompromising Python code formatter]],
    homepage = "https://pypi.org/project/black/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "black", bin = { "black" } },
}
