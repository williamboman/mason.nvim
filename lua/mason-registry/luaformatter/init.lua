local Pkg = require "mason-core.package"
local git = require "mason-core.managers.git"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "luaformatter",
    desc = [[Code formatter for Lua]],
    homepage = "https://github.com/Koihik/LuaFormatter",
    languages = { Pkg.Lang.Lua },
    categories = { Pkg.Cat.Formatter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local source = github.tag { repo = "Koihik/LuaFormatter" }
        source.with_receipt()
        git.clone { "https://github.com/Koihik/LuaFormatter", version = Optional.of(source.tag), recursive=true }
        ctx.spawn.cmake { "." }
        ctx.spawn.make { }
        ctx:link_bin("lua-format", platform.is.win and "lua-format.exe" or "lua-format")
    end,
}
