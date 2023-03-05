local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "cmakelint",
    desc = [[cmakelint parses CMake files and reports style issues]],
    homepage = "https://github.com/cmake-lint/cmake-lint",
    languages = { Pkg.Lang.CMake },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "cmakelint", bin = { "cmakelint" } },
}
