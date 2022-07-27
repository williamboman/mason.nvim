local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local std = require "mason-core.managers.std"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "actionlint",
    desc = [[Static checker for GitHub Actions workflow files]],
    homepage = "https://github.com/rhysd/actionlint",
    languages = { Pkg.Lang.YAML },
    categories = { Pkg.Cat.Linter },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "rhysd/actionlint"
        local function format_release_file(file)
            return _.compose(_.format(file), _.gsub("^v", ""))
        end

        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.mac_x64, format_release_file "actionlint_%s_darwin_amd64.tar.gz"),
                            when(platform.is.mac_arm64, format_release_file "actionlint_%s_darwin_arm64.tar.gz"),
                            when(platform.is.linux_x64, format_release_file "actionlint_%s_linux_amd64.tar.gz"),
                            when(platform.is.linux_arm, format_release_file "actionlint_%s_linux_armv6.tar.gz"),
                            when(platform.is.linux_arm64, format_release_file "actionlint_%s_linux_arm64.tar.gz"),
                            when(platform.is.linux_x86, format_release_file "actionlint_%s_linux_386.tar.gz")
                        ),
                    })
                    .with_receipt()
                std.chmod("+x", { "actionlint" })
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.win_arm64, format_release_file "actionlint_%s_windows_arm64.zip"),
                            when(platform.is.win_x64, format_release_file "actionlint_%s_windows_amd64.zip"),
                            when(platform.is.win_x86, format_release_file "actionlint_%s_windows_386.zip")
                        ),
                    })
                    .with_receipt()
            end,
        }
        ctx:link_bin("actionlint", platform.is.win and "actionlint.exe" or "actionlint")
    end,
}
