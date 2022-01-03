local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local installers = require "nvim-lsp-installer.installers"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/latex-lsp/texlab",
        languages = { "latex" },
        installer = {
            context.use_github_release_file(
                "latex-lsp/texlab",
                coalesce(
                    when(platform.is_mac, "texlab-x86_64-macos.tar.gz"),
                    when(platform.is_linux, "texlab-x86_64-linux.tar.gz"),
                    when(platform.is_win, "texlab-x86_64-windows.zip")
                )
            ),
            context.capture(function(ctx)
                return installers.when {
                    unix = std.untargz_remote(ctx.github_release_file),
                    win = std.unzip_remote(ctx.github_release_file),
                }
            end),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
