local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"

return Pkg.new {
    name = "erg-language-server",
    desc = [[ELS is a language server for the Erg programing language.]],
    homepage = "https://github.com/erg-lang/erg",
    languages = { Pkg.Lang.Erg },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "erg-lang/erg"
        local asset_file = _.coalesce(
            _.when(platform.is.mac_x64, "erg-x86_64-apple-darwin.tar.gz"),
            _.when(platform.is.mac_arm64, "erg-aarch64-apple-darwin.tar.gz"),
            _.when(platform.is.linux_x64_gnu, "erg-x86_64-unknown-linux-gnu.tar.gz"),
            _.when(platform.is.win_x64, "erg-x86_64-pc-windows-msvc.zip")
        )
        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = asset_file,
                    })
                    .with_receipt()
                ctx:link_bin("erg", "erg")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = asset_file,
                    })
                    .with_receipt()
                ctx:link_bin("erg", "erg.exe")
            end,
        }
    end,
}
