local Pkg = require "mason-core.package"
local luarocks = require "mason-core.managers.luarocks"

return Pkg.new {
    name = "luaformatter",
    desc = [[Code formatter for Lua]],
    homepage = "https://github.com/Koihik/LuaFormatter",
    languages = { Pkg.Lang.Lua },
    categories = { Pkg.Cat.Formatter },
    install = luarocks.package("luaformatter", {
        server = "https://luarocks.org/dev",
        bin = { "lua-format" },
    }),
}
