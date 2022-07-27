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
        platform.when {
            mac = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("actionlint_%s_darwin_arm64.tar.gz"):format(version:gsub("^v", ""))
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("actionlint_%s_darwin_amd64.tar.gz"):format(version:gsub("^v", ""))
                            end)
                        ),
                    })
                    :with_receipt()
            end,
            linux = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("actionlint_%s_linux_arm64.tar.gz"):format(version:gsub("^v", ""))
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("actionlint_%s_linux_amd64.tar.gz"):format(version:gsub("^v", ""))
                            end),
                            when(platform.arch == "x86", function(version)
                                return ("actionlint_%s_linux_386.tar.gz"):format(version:gsub("^v", ""))
                            end)
                        ),
                    })
                    .with_receipt()
            end,
            win = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("actionlint_%s_windows_arm64.zip"):format(version:gsub("^v", ""))
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("actionlint_%s_windows_amd64.zip"):format(version:gsub("^v", ""))
                            end),
                            when(platform.arch == "x86", function(version)
                                return ("actionlint_%s_windows_386.zip"):format(version:gsub("^v", ""))
                            end)
                        ),
                    })
                    .with_receipt()
            end,
        }
        std.chmod("+x", { "actionlint" })
        ctx:link_bin("actionlint", platform.is.win and "actionlint.exe" or "actionlint")
    end,
}
