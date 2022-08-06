local Pkg = require "mason-core.package"
local pip3 = require "mason-core.managers.pip3"

return Pkg.new {
    name = "vulture",
    desc = [[Vulture finds unused code in Python programs.]],
    homepage = "https://github.com/jendrikseipp/vulture",
    languages = { Pkg.Lang.Python },
    categories = { Pkg.Cat.Linter },
    install = pip3.packages { "vulture", bin = { "vulture" } },
}
