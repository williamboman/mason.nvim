local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "cspell",
    desc = [[A Spell Checker for Code]],
    homepage = "https://github.com/streetsidesoftware/cspell",
    languages = {},
    categories = { Pkg.Cat.Linter },
    install = npm.packages { "cspell", bin = { "cspell" } },
}
