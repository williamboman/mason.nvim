local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local npm = require "nvim-lsp-installer.installers.npm"
local path = require "nvim-lsp-installer.path"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/vshaxe/haxe-language-server",
        languages = { "haxe" },
        installer = {
            std.ensure_executables {
                {
                    "haxelib",
                    "haxelib was not found in path. Refer to https://haxe.org/ for installation instructions.",
                },
            },
            std.git_clone "https://github.com/vshaxe/haxe-language-server",
            npm.install(),
            npm.exec("lix", { "run", "vshaxe-build", "-t", "language-server" }),
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.git_remote "https://github.com/vshaxe/haxe-language-server")
            end),
        },
        default_options = {
            cmd = { "node", path.concat { root_dir, "bin", "server.js" } },
        },
    }
end
