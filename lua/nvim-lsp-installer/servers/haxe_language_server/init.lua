local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local std = require "nvim-lsp-installer.core.managers.std"
local git = require "nvim-lsp-installer.core.managers.git"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/vshaxe/haxe-language-server",
        languages = { "haxe" },
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable("haxelib", { help_url = "https://haxe.org" })
            git.clone({ "https://github.com/vshaxe/haxe-language-server" }).with_receipt()
            ctx.spawn.npm { "install" }
            npm.exec { "lix", "run", "vshaxe-build", "-t", "language-server" }
        end,
        default_options = {
            cmd = { "node", path.concat { root_dir, "bin", "server.js" } },
        },
    }
end
