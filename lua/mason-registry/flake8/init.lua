local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "flake8",
    desc = _.dedent [[
        flake8 is a python tool that glues together pycodestyle, pyflakes, mccabe, and third-party plugins to check the
        style and quality of some python code.
    ]],
    homepage = "https://github.com/PyCQA/flake8",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "flake8", bin = { "flake8" } },
}
