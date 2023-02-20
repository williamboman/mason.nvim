local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "autopep8",
    desc = [[A tool that automatically formats Python code to conform to the PEP 8 style guide]],
    homepage = "https://pypi.org/project/autopep8/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "autopep8", bin = { "autopep8" } },
}
