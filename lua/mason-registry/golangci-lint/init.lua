local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

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
        local repo = "golangci/golangci-lint"
        ---@param template_string string
        local function release_file(template_string)
            return _.compose(_.format(template_string), _.gsub("^v", ""))
        end

        platform.when {
            unix = function()
                local source = github.untargz_release_file {
                    repo = repo,
                    asset_file = coalesce(
                        when(platform.is.linux_armv6l, release_file "golangci-lint-%s-linux-armv6.tar.gz"),
                        when(platform.is.linux_armv7l, release_file "golangci-lint-%s-linux-armv7.tar.gz"),
                        when(platform.is.linux_x64, release_file "golangci-lint-%s-linux-amd64.tar.gz"),
                        when(platform.is.linux_x86, release_file "golangci-lint-%s-linux-386.tar.gz"),
                        when(platform.is.darwin_x64, release_file "golangci-lint-%s-darwin-amd64.tar.gz"),
                        when(platform.is.darwin_arm64, release_file "golangci-lint-%s-darwin-arm64.tar.gz")
                    ),
                }
                source.with_receipt()
                local directory = source.asset_file:gsub("%.tar%.gz$", "")
                ctx:link_bin("golangci-lint", path.concat { directory, "golangci-lint" })
            end,
            win = function()
                local source = github.unzip_release_file {
                    repo = repo,
                    asset_file = coalesce(
                        when(platform.is.win_x64, release_file "golangci-lint-%s-windows-amd64.zip"),
                        when(platform.is.win_x86, release_file "golangci-lint-%s-windows-386.zip")
                    ),
                }
                source.with_receipt()
                local directory = source.asset_file:gsub("%.zip$", "")
                ctx:link_bin("golangci-lint", path.concat { directory, "golangci-lint.exe" })
            end,
        }
    end,
}
