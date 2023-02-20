local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "isort",
    desc = [[isort is a Python utility / library to sort imports alphabetically]],
    homepage = "https://pypi.org/project/isort/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "isort", bin = { "isort" } },
}
