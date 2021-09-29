local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            context.github_release_file(
                "denoland/deno",
                Data.coalesce(
                    Data.when(
                        platform.is_mac,
                        Data.coalesce(
                            Data.when(platform.arch == "arm64", "deno-aarch64-apple-darwin.zip"),
                            Data.when(platform.arch == "x64", "deno-x86_64-apple-darwin.zip")
                        )
                    ),
                    Data.when(platform.is_linux, "deno-x86_64-unknown-linux-gnu.zip"),
                    Data.when(platform.is_win, "deno-x86_64-pc-windows-msvc.zip")
                )
            ),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
        },
        default_options = {
            cmd = { path.concat { root_dir, "bin", "deno" }, "lsp" },
        },
    }
end
