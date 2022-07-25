local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "mypy",
    desc = [[Mypy is a static type checker for Python. ]],
    homepage = "https://github.com/python/mypy",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "mypy", bin = { "mypy" } },
}
