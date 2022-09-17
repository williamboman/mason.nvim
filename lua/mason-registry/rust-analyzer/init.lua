local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "rust-analyzer",
    desc = _.dedent [[
        rust-analyzer is an implementation of Language Server Protocol for the Rust programming language. It provides
        features like completion and goto definition for many code editors, including VS Code, Emacs and Vim.
    ]],
    homepage = "https://rust-analyzer.github.io",
    languages = { Pkg.Lang.Rust },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local asset_file = coalesce(
            when(platform.is.mac_arm64, "rust-analyzer-aarch64-apple-darwin.gz"),
            when(platform.is.mac_x64, "rust-analyzer-x86_64-apple-darwin.gz"),
            when(platform.is.linux_x64_gnu, "rust-analyzer-x86_64-unknown-linux-gnu.gz"),
            when(platform.is.linux_arm64_gnu, "rust-analyzer-aarch64-unknown-linux-gnu.gz"),
            when(platform.is.linux_x64_musl, "rust-analyzer-x86_64-unknown-linux-musl.gz"),
            when(platform.is.win_arm64, "rust-analyzer-aarch64-pc-windows-msvc.gz"),
            when(platform.is.win_x64, "rust-analyzer-x86_64-pc-windows-msvc.gz")
        )

        github
            .gunzip_release_file({
                repo = "rust-lang/rust-analyzer",
                asset_file = asset_file,
                out_file = platform.is.win and "rust-analyzer.exe" or "rust-analyzer",
            })
            .with_receipt()
        std.chmod("+x", { "rust-analyzer" })
        ctx:link_bin("rust-analyzer", platform.is.win and "rust-analyzer.exe" or "rust-analyzer")
    end,
}
