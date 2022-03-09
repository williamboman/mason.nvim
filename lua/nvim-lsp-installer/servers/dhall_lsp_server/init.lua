local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"

local coalesce, when = Data.coalesce, Data.when

local target = coalesce(
    when(platform.is_mac, "dhall-lsp-server-1.0.18-x86_64-macos.tar.bz2"),
    when(platform.is_linux, "dhall-lsp-server-1.0.18-x86_64-linux.tar.bz2"),
    when(platform.is_win, "dhall-lsp-server-1.0.18-x86_64-windows.zip")
)

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://dhall-lang.org/",
        languages = { "dhall" },
        installer = {
            context.set(function(ctx)
                ctx.requested_server_version = Data.coalesce(
                    ctx.requested_server_version,
                    "1.41.1" -- https://github.com/williamboman/nvim-lsp-installer/pull/512#discussion_r817062340
                )
            end),
            context.use_github_release_file("dhall-lang/dhall-haskell", target),
            context.capture(function(ctx)
                if platform.is_win then
                    return std.unzip_remote(ctx.github_release_file)
                else
                    return std.untargz_remote(ctx.github_release_file)
                end
            end),
            std.chmod("+x", { path.concat { "bin", "dhall-lsp-server" } }),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
