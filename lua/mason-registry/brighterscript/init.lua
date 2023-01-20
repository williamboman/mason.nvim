local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "brighterscript",
    desc = [[A superset of Roku's BrightScript language.]],
    homepage = "https://github.com/RokuCommunity/brighterscript",
    languages = { Pkg.Lang.Brighterscript },
    categories = { Pkg.Cat.LSP, Pkg.Cat.Compiler },
    install = npm.packages { "brighterscript", bin = { "brighterscript" } },
}

