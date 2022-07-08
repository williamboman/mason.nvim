local Pkg = require "mason-core.package"
local github = require "mason-core.managers.github"
local github_client = require "mason-core.managers.github.client"
local std = require "mason-core.managers.std"
local _ = require "mason-core.functional"
local platform = require "mason-core.platform"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "vls",
    desc = [[V language server]],
    homepage = "https://github.com/vlang/vls",
    languages = { Pkg.Lang.V },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "vlang/vls"

        ---@type GitHubRelease
        local latest_dev_build = github_client.fetch_latest_release(repo, { include_prerelease = true }):get_or_throw()

        github
            .download_release_file({
                version = Optional.of(latest_dev_build.tag_name),
                repo = repo,
                out_file = platform.is.win and "vls.exe" or "vls",
                asset_file = _.coalesce(
                    _.when(platform.is.linux_x64, "vls_linux_x64"),
                    _.when(platform.is.mac, "vls_macos_x64"),
                    _.when(platform.is.win_x64, "vls_windows_x64.exe")
                ),
            })
            .with_receipt()
        std.chmod("+x", { "vls" })
        ctx:link_bin("vls", platform.is.win and "vls.exe" or "vls")
    end,
}
