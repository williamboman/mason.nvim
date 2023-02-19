local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "erg-language-server",
    desc = [[ELS is a language server for the Erg programing language.]],
    homepage = "https://github.com/erg-lang/erg-language-server",
    languages = { Pkg.Lang.Erg },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "erg-lang/erg-language-server"
        local asset_file = _.coalesce(
            _.when(platform.is.mac_x64, "els-x86_64-apple-darwin.tar.gz"),
            _.when(platform.is.mac_arm64, "els-aarch64-apple-darwin.tar.gz"),
            _.when(platform.is.linux_arm64_gnu, "els-aarch64-unknown-linux-gnu.tar.gz"),
            _.when(platform.is.linux_x64_gnu, "els-x86_64-unknown-linux-gnu.tar.gz"),
            _.when(platform.is.linux_x64, "els-x86_64-unknown-linux-musl.tar.gz"),
            _.when(platform.is.win_x64, "els-x86_64-pc-windows-msvc.zip")
        )
        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = asset_file,
                    })
                    .with_receipt()
                ctx:link_bin("els", "els")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = asset_file,
                    })
                    .with_receipt()
                ctx:link_bin("els", "els.exe")
            end,
        }
    end,
}
