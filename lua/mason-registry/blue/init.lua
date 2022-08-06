local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "blue",
    desc = [[blue is a somewhat less uncompromising code formatter than black, the OG of Python formatters.]],
    homepage = "https://github.com/grantjenks/blue",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "blue", bin = { "blue" } },
}
