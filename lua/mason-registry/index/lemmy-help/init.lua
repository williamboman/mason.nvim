local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"

return Pkg.new {
    name = "lemmy-help",
    desc = [[Every one needs help, so lemmy-help you! A CLI to generate vim/nvim help doc from emmylua]],
    homepage = "https://github.com/numToStr/lemmy-help",
    categories = {},
    languages = { Pkg.Lang.Lua },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "numToStr/lemmy-help"
        local asset_file = _.coalesce(
            _.when(platform.is.mac, "lemmy-help-x86_64-apple-darwin.tar.gz"),
            _.when(platform.is.linux_x64_gnu, "lemmy-help-x86_64-unknown-linux-gnu.tar.gz"),
            _.when(platform.is.linux_x64, "lemmy-help-x86_64-unknown-linux-musl.tar.gz"),
            _.when(platform.is.linux_arm64_gnu, "lemmy-help-aarch64-unknown-linux-gnu.tar.gz"),
            _.when(platform.is.linux_arm64, "lemmy-help-aarch64-unknown-linux-musl.tar.gz"),
            _.when(platform.is.win_x64, "lemmy-help-x86_64-pc-windows-msvc.zip")
        )
        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = asset_file,
                    })
                    .with_receipt()
                ctx:link_bin("lemmy-help", "lemmy-help")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = asset_file,
                    })
                    .with_receipt()
                ctx:link_bin("lemmy-help", "lemmy-help.exe")
            end,
        }
    end,
}
