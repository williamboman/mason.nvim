local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local github = require "mason-core.managers.github"
local path = require "mason-core.path"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
    name = "editorconfig-checker",
    desc = [[A tool to verify that your files are in harmony with your `.editorconfig`.]],
    homepage = "https://github.com/editorconfig-checker/editorconfig-checker",
    languages = {},
    categories = { Pkg.Cat.Linter },
    install = function(ctx)
        local source = github.untargz_release_file {
            repo = "editorconfig-checker/editorconfig-checker",
            asset_file = coalesce(
                when(platform.is.mac_arm64, "ec-darwin-arm64.tar.gz"),
                when(platform.is.mac_x64, "ec-darwin-amd64.tar.gz"),
                when(platform.is.linux_x64_openbsd, "ec-openbsd-amd64.tar.gz"),
                when(platform.is.linux_arm64_openbsd, "ec-openbsd-arm64.tar.gz"),
                when(platform.is.linux_arm64, "ec-linux-arm64.tar.gz"),
                when(platform.is.linux_x64, "ec-linux-amd64.tar.gz"),
                when(platform.is.win_x86, "ec-windows-386.tar.gz"),
                when(platform.is.win_x64, "ec-windows-amd64.tar.gz")
            ),
        }
        source.with_receipt()
        local prog = source.asset_file:gsub("%.tar%.gz$", "")
        ctx:link_bin("editorconfig-checker", path.concat { "bin", prog })
    end,
}
