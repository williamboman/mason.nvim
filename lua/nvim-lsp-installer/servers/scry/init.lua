local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "crystal" },
        homepage = "https://github.com/crystal-lang-tools/scry",
        installer = {
            std.ensure_executables {
                {
                    "crystal",
                    "crystal was not found in path. Refer to https://crystal-lang.org/install/ for installation instructions.",
                },
                {
                    "shards",
                    "shards was not found in path. Refer to https://crystal-lang.org/install/ for installation instructions.",
                },
            },
            std.git_clone "https://github.com/crystal-lang-tools/scry.git",
            ---@type ServerInstallerFunction
            function(_, callback, ctx)
                process.spawn("shards", {
                    args = { "build", "--verbose", "--release" },
                    cwd = ctx.install_dir,
                    stdio_sink = ctx.stdio_sink,
                }, callback)
            end,
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.git_remote "https://github.com/crystal-lang-tools/scry.git")
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
