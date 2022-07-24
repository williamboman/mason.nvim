local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "vale",
    desc = [[📝 A syntax-aware linter for prose built with speed and extensibility in mind.]],
    homepage = "https://vale.sh/",
    languages = { Pkg.Lang.Text, Pkg.Lang.Markdown, Pkg.Lang.LaTeX },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "errata-ai/vale"
        local release_file = assert(
            coalesce(
                when(platform.is.mac_x64, "vale_%s_macOS_64-bit.tar.gz"),
                when(platform.is.mac_arm64, "vale_%s_macOS_arm64.tar.gz"),
                when(platform.is.linux_x64, "vale_%s_Linux_64-bit.tar.gz"),
                when(platform.is.linux_arm64, "vale_%s_Linux_arm64.tar.gz"),
                when(platform.is.win_x64, "vale_%s_Windows_64-bit.zip")
            ),
            "Current platform is not supported."
        )

        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = _.compose(_.format(release_file), _.gsub("^v", "")),
                    })
                    .with_receipt()
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = _.compose(_.format(release_file), _.gsub("^v", "")),
                    })
                    .with_receipt()
            end,
        }
        ctx:link_bin("vale", platform.is.win and "vale.exe" or "vale")
    end,
}
