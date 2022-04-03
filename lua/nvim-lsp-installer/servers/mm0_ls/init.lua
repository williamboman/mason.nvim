local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "metamath-zero" },
        homepage = "https://github.com/digama0/mm0",
        installer = {
            std.git_clone "https://github.com/digama0/mm0",
            ---@type ServerInstallerFunction
            function(_, callback, ctx)
                process.spawn("cargo", {
                    args = { "build", "--release" },
                    cwd = path.concat { ctx.install_dir, "mm0-rs" },
                    stdio_sink = ctx.stdio_sink,
                }, callback)
            end,
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.git_remote "https://github.com/digama0/mm0")
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "mm0-rs", "target", "release" } },
            },
        },
    }
end
