local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "codespell",
    desc = [[check code for common misspellings]],
    homepage = "https://github.com/codespell-project/codespell",
    languages = {},
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "codespell", bin = { "codespell" } },
}
