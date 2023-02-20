local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "cmakelang",
    desc = [[Language tools for cmake (format, lint, etc)]],
    homepage = "https://pypi.org/project/cmakelang/",
    languages = { Pkg.Lang.CMake },
    categories = { Pkg.Cat.Formatter, Pkg.Cat.Linter },
    install = pip3.packages {
        "cmakelang",
        bin = {
            "cmake-annotate",
            "cmake-format",
            "cmake-lint",
            "ctest-to",
        },
    },
}
