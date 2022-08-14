local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "yapf",
    desc = [[Yapf, Yet another python formatter]],
    homepage = "https://pypi.org/project/yapf/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Formatter },
    install = pip3.packages { "yapf", bin = { "yapf" } },
}
