local Pkg = require "mason.core.package"
local cargo = require "mason.core.managers.cargo"

return Pkg.new {
    name = "stylua",
    desc = [[An opinionated Lua code formatter]],
    homepage = "https://github.com/JohnnyMorganz/StyLua",
    languages = { Pkg.Lang.Lua },
    categories = { Pkg.Cat.Formatter },
    install = cargo.crate("stylua", {
        bin = { "stylua" }
    }),
}
