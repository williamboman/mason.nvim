local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://deno.land/x/deno/cli/lsp",
        languages = { "deno" },
        installer = function()
            github.unzip_release_file({
                repo = "denoland/deno",
                asset_file = coalesce(
                    when(
                        platform.is_mac,
                        coalesce(
                            when(platform.arch == "arm64", "deno-aarch64-apple-darwin.zip"),
                            when(platform.arch == "x64", "deno-x86_64-apple-darwin.zip")
                        )
                    ),
                    when(platform.is_linux, "deno-x86_64-unknown-linux-gnu.zip"),
                    when(platform.is_win, "deno-x86_64-pc-windows-msvc.zip")
                ),
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
