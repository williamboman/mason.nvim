local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "gersemi",
    desc = [[gersemi - A formatter to make your CMake code the real treasure.]],
    homepage = "https://github.com/BlankSpruce/gersemi",
    languages = { Pkg.Lang.CMake },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages {
        "gersemi",
        bin = {
            "gersemi",
        },
    },
}
