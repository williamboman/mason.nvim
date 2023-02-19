local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "rstcheck",
    desc = "Checks syntax of reStructuredText and code blocks nested within it.",
    homepage = "https://rstcheck.readthedocs.io/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "rstcheck", bin = { "rstcheck" } },
}
