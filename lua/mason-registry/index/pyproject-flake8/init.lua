local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "pyproject-flake8",
    desc = "A monkey patching wrapper to connect flake8 with pyproject.toml configuration.",
    homepage = "https://github.com/csachs/pyproject-flake8",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pyproject-flake8", bin = { "pflake8" } },
}
