local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "vulture",
    desc = _.dedent [[
       Vulture finds unused code in Python programs. This is useful for cleaning up and finding errors in large code
       bases. If you run Vulture on both your library and test suite you can find untested code.

       Due to Python's dynamic nature, static code analyzers like Vulture are likely to miss some dead code. Also, code
       that is only called implicitly may be reported as unused. Nonetheless, Vulture can be a very helpful tool for
       higher code quality.
    ]],
    homepage = "https://github.com/jendrikseipp/vulture",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "vulture", bin = { "vulture" } },
}
