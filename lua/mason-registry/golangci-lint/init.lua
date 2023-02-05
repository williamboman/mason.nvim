local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "golangci-lint",
    desc = _.dedent [[
        golangci-lint is a fast Go linters runner. It runs linters in parallel, uses caching, supports yaml config, has
        integrations with all major IDE and has dozens of linters included.
    ]],
    homepage = "https://golangci-lint.run/",
    languages = { Pkg.Lang.Go },
    categories = { Pkg.Cat.Linter },
    install = function(ctx)
        local folder = nil
        local repo = "golangci/golangci-lint"

        local function format_release_file(os, arch, suffix)
            return function(version)
                version = string.sub(version, 2)
                folder = string.format("golangci-lint-%s-%s-%s", version, os, arch)
                return folder .. "." .. suffix
            end
        end

        platform.when {
            unix = function()
                github
                    .untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.linux_x64, format_release_file("linux", "amd64", "tar.gz")),
                            when(platform.is.linux_x86, format_release_file("linux", "386", "tar.gz")),
                            when(platform.is.darwin_x64, format_release_file("darwin", "amd64", "tar.gz")),
                            when(platform.is.darwin_arm64, format_release_file("darwin", "arm64", "tar.gz"))
                        ),
                    })
                    .with_receipt()
                ctx:chdir(folder)
                ctx:link_bin("golangci-lint", "golangci-lint")
            end,
            win = function()
                github
                    .unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is.win_x64, format_release_file("windows", "amd64", "zip")),
                            when(platform.is.win_x86, format_release_file("windows", "386", "zip"))
                        ),
                    })
                    .with_receipt()
                ctx:chdir(folder)
                ctx:link_bin("golangci-lint.exe", "golangci-lint.exe")
            end,
        }
    end,
}
