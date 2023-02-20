local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "brighterscript-formatter",
    desc = [[A code formatter for BrightScript and BrighterScript.]],
    homepage = "https://github.com/rokucommunity/brighterscript-formatter",
    languages = { Pkg.Lang.BrighterScript },
    categories = { Pkg.Cat.Formatter },
    install = npm.packages { "brighterscript-formatter", bin = { "bsfmt" } },
}
