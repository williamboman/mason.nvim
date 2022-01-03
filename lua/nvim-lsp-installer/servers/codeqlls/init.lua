local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local context = require "nvim-lsp-installer.installers.context"
local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "codeql" },
        installer = {
            context.use_github_release_file(
                "github/codeql-cli-binaries",
                coalesce(
                    when(platform.is_mac, "codeql-osx64.zip"),
                    when(platform.is_unix, "codeql-linux64.zip"),
                    when(platform.is_win, "codeql-win64.zip")
                )
            ),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "codeql" } },
            },
        },
    }
end
