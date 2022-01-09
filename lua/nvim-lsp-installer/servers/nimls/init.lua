local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/PMunch/nimlsp",
        languages = { "nim" },
        installer = {
            std.git_clone "https://github.com/PMunch/nimlsp.git",
            function(_, callback, ctx)
                process.spawn("nimble", {
                    args = { "build", "-y", "--localdeps" },
                    cwd = ctx.install_dir,
                    stdio_sink = ctx.stdio_sink,
                }, callback)
            end,
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.git_remote "https://github.com/PMunch/nimlsp.git")
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
