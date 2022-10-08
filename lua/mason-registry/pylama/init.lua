local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pylama",
    desc = [[Code audit tool for python]],
    homepage = "https://github.com/klen/pylama",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pylama[all]", bin = { "pylama" } },
}
