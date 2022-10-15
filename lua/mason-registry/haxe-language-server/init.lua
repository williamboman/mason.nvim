local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local git = require "mason-core.managers.git"
local npm = require "mason-core.managers.npm"
local path = require "mason-core.path"

return Pkg.new {
    name = "haxe-language-server",
    desc = [[Language Server Protocol implementation for the Haxe language]],
    homepage = "https://github.com/vshaxe/haxe-language-server",
    languages = { Pkg.Lang.Haxe },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable("haxelib", { help_url = "https://haxe.org" })
        git.clone({ "https://github.com/vshaxe/haxe-language-server" }).with_receipt()
        ctx.spawn.npm { "install" }
        npm.exec { "lix", "run", "vshaxe-build", "-t", "language-server" }
        ctx.spawn.npm { "install", "--production" }
        ctx:link_bin(
            "haxe-language-server",
            ctx:write_node_exec_wrapper("haxe-language-server", path.concat { "bin", "server.js" })
        )
    end,
}
