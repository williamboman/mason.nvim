local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://rust-analyzer.github.io",
        languages = { "rust" },
        installer = function()
            local libc = platform.get_libc()

            local asset_file = coalesce(
                when(
                    platform.is_mac,
                    coalesce(
                        when(platform.arch == "arm64", "rust-analyzer-aarch64-apple-darwin.gz"),
                        when(platform.arch == "x64", "rust-analyzer-x86_64-apple-darwin.gz")
                    )
                ),
                when(
                    platform.is_linux,
                    coalesce(
                        when(
                            libc == "glibc",
                            coalesce(
                                when(platform.arch == "arm64", "rust-analyzer-aarch64-unknown-linux-gnu.gz"),
                                when(platform.arch == "x64", "rust-analyzer-x86_64-unknown-linux-gnu.gz")
                            )
                        ),
                        when(
                            libc == "musl",
                            coalesce(when(platform.arch == "x64", "rust-analyzer-x86_64-unknown-linux-musl.gz"))
                        )
                    )
                ),
                when(
                    platform.is_win,
                    coalesce(
                        when(platform.arch == "arm64", "rust-analyzer-aarch64-pc-windows-msvc.gz"),
                        when(platform.arch == "x64", "rust-analyzer-x86_64-pc-windows-msvc.gz")
                    )
                )
            )

            github.gunzip_release_file({
                repo = "rust-lang/rust-analyzer",
                asset_file = asset_file,
                out_file = platform.is_win and "rust-analyzer.exe" or "rust-analyzer",
            }).with_receipt()
            std.chmod("+x", { "rust-analyzer" })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
