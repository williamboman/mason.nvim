local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "beartype",
    desc = [[Beartype is an PEP-compliant and near-real-time type checker for Python emphasizing efficiency and usability ]],
    homepage = "https://pypi.org/project/beartype/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "beartype", bin = { "beartype" } },
}
