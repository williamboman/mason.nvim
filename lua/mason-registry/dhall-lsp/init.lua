local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local std = require "mason-core.managers.std"
local github_client = require "mason-core.managers.github.client"
local Optional = require "mason-core.optional"

return Pkg.new {
    name = "dhall-lsp",
    desc = [[LSP server implementation for Dhall.]],
    homepage = "https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-lsp-server",
    languages = { Pkg.Lang.Dhall },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local repo = "dhall-lang/dhall-haskell"
        ---@type GitHubRelease
        local gh_release = ctx.requested_version
            :map(function(version)
                return github_client.fetch_release(repo, version)
            end)
            :or_else_get(function()
                return github_client.fetch_latest_release(repo)
            end)
            :get_or_throw()

        local asset_name_pattern = assert(
            _.coalesce(
                _.when(platform.is.mac, "dhall%-lsp%-server%-.+%-x86_64%-macos.tar.bz2"),
                _.when(platform.is.linux_x64, "dhall%-lsp%-server%-.+%-x86_64%-linux.tar.bz2"),
                _.when(platform.is.win_x64, "dhall%-lsp%-server%-.+%-x86_64%-windows.zip")
            )
        )
        local dhall_lsp_server_asset =
            _.find_first(_.prop_satisfies(_.matches(asset_name_pattern), "name"), gh_release.assets)
        Optional.of_nilable(dhall_lsp_server_asset)
            :if_present(
                ---@param asset GitHubReleaseAsset
                function(asset)
                    if platform.is.win then
                        std.download_file(asset.browser_download_url, "dhall-lsp-server.zip")
                        std.unzip("dhall-lsp-server.zip", ".")
                    else
                        std.download_file(asset.browser_download_url, "dhall-lsp-server.tar.bz2")
                        std.untar "dhall-lsp-server.tar.bz2"
                        std.chmod("+x", { path.concat { "bin", "dhall-lsp-server" } })
                    end
                    ctx.receipt:with_primary_source {
                        type = "github_release_file",
                        repo = repo,
                        file = asset.browser_download_url,
                        release = gh_release.tag_name,
                    }
                end
            )
            :or_else_throw "Unable to find the dhall-lsp-server release asset in the GitHub release."

        ctx:link_bin(
            "dhall-lsp-server",
            path.concat { "bin", platform.is.win and "dhall-lsp-server.exe" or "dhall-lsp-server" }
        )
    end,
}
