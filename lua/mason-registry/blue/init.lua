local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "blue",
    desc = _.dedent [[
        blue is a somewhat less uncompromising code formatter than black, the OG of Python formatters. We love the idea
        of automatically formatting Python code, for the same reasons that inspired black, however we take issue with
        some of the decisions black makes. Kudos to black for pioneering code formatting for Python, and for its
        excellent implementation.
    ]],
    homepage = "https://blue.readthedocs.io/en/latest/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "blue", bin = { "blue" } },
}
