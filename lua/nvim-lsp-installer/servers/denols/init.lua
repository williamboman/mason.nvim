local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://deno.land/x/deno/cli/lsp",
        languages = { "deno" },
        installer = {
            context.use_github_release_file(
                "denoland/deno",
                coalesce(
                    when(
                        platform.is_mac,
                        coalesce(
                            when(platform.arch == "arm64", "deno-aarch64-apple-darwin.zip"),
                            when(platform.arch == "x64", "deno-x86_64-apple-darwin.zip")
                        )
                    ),
                    when(platform.is_linux, "deno-x86_64-unknown-linux-gnu.zip"),
                    when(platform.is_win, "deno-x86_64-pc-windows-msvc.zip")
                )
            ),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
        },
        default_options = {
            cmd = { path.concat { root_dir, "deno" }, "lsp" },
        },
    }
end
