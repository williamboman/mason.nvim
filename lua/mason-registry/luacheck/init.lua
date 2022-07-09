local Pkg = require "mason-core.package"
local luarocks = require "mason-core.managers.luarocks"

return Pkg.new {
    name = "luacheck",
    desc = [[A tool for linting and static analysis of Lua code.]],
    homepage = "https://github.com/mpeterv/luacheck",
    languages = { Pkg.Lang.Lua },
    categories = { Pkg.Cat.Linter },
    install = luarocks.package("luacheck", {
        bin = { "luacheck" },
    }),
}
