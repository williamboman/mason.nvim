local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"

local coalesce, when = Data.coalesce, Data.when

local target = coalesce(
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
            when(platform.arch == "arm64", "rust-analyzer-aarch64-unknown-linux-gnu.gz"),
            when(platform.arch == "x64", "rust-analyzer-x86_64-unknown-linux-gnu.gz")
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

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://rust-analyzer.github.io",
        languages = { "rust" },
        installer = {
            context.use_github_release_file("rust-analyzer/rust-analyzer", target),
            context.capture(function(ctx)
                return std.gunzip_remote(
                    ctx.github_release_file,
                    platform.is_win and "rust-analyzer.exe" or "rust-analyzer"
                )
            end),
            std.chmod("+x", { "rust-analyzer" }),
        },
        default_options = {
            cmd = { path.concat { root_dir, "rust-analyzer" } },
        },
    }
end
