local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "pyflakes",
    desc = _.dedent [[
        A simple program which checks Python source files for errors.

        Pyflakes analyzes programs and detects various errors. It works by parsing the source file, not importing it, so
        it is safe to use on modules with side effects. It’s also much faster.
]],
    homepage = "https://pypi.org/project/pyflakes/",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "pyflakes", bin = { "pyflakes" } },
}
