local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pydocstyle",
    desc = "pydocstyle is a static analysis tool for checking compliance with Python docstring conventions",
    homepage = "https://www.pydocstyle.org/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pydocstyle", bin = { "pydocstyle" } },
}
