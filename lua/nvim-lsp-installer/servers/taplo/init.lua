local server = require "nvim-lsp-installer.server"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"
local installers = require "nvim-lsp-installer.installers"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "toml" },
        homepage = "https://taplo.tamasfe.dev/lsp/",
        installer = {
            context.use_github_release_file(
                "tamasfe/taplo",
                coalesce(
                    when(platform.is_mac, "taplo-lsp-x86_64-apple-darwin-gnu.tar.gz"),
                    when(platform.is_linux and platform.arch == "x64", "taplo-lsp-x86_64-unknown-linux-gnu.tar.gz"),
                    when(platform.is_win and platform.arch == "x64", "taplo-lsp-windows-x86_64.zip")
                ),
                {
                    tag_name_pattern = "^release%-lsp%-",
                }
            ),
            context.capture(function(ctx)
                return installers.when {
                    unix = std.untargz_remote(ctx.github_release_file),
                    win = std.unzip_remote(ctx.github_release_file),
                }
            end),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx, {
                    tag_name_pattern = "^release%-lsp%-",
                }))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
