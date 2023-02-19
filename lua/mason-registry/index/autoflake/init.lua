local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "autoflake",
    desc = [[autoflake removes unused imports and unused variables from Python code.]],
    homepage = "https://pypi.org/project/autoflake/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "autoflake", bin = { "autoflake" } },
}
