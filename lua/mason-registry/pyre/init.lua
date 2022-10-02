local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pyre",
    desc = [[Pyre is a performant type checker for Python compliant with PEP 484]],
    homepage = "https://pypi.org/project/pyre-check/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pyre-check", bin = { "pyre" } },
}
