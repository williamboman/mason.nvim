local Pkg = require "mason-core.package"
local npm = require "mason-core.managers.npm"

return Pkg.new {
    name = "brightscript",
    desc = [[A syntax and static analysis for brs files]],
    homepage = "https://github.com/RokuCommunity/brighterscript",
    languages = { Pkg.Lang.Brighterscript },
    categories = { Pkg.Cat.LSP },
    install = npm.packages { "brighterscript", bin = { "brighterscript" } },
}

