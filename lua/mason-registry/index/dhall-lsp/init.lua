local Pkg = require "mason-core.package"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local std = require "mason-core.managers.std"
local github_client = require "mason-core.managers.github.client"
local Optional = require "mason-core.optional"
local Result = require "mason-core.result"

return Pkg.new {
    name = "dhall-lsp",
    desc = [[LSP server implementation for Dhall.]],
    homepage = "https://github.com/dhall-lang/dhall-haskell/tree/master/dhall-lsp-server",
    languages = { Pkg.Lang.Dhall },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        local asset_name_pattern = assert(
            _.coalesce(
                _.when(platform.is.mac, "dhall%-lsp%-server%-.+%-x86_64%-[mM]acos.tar.bz2"),
                _.when(platform.is.linux_x64, "dhall%-lsp%-server%-.+%-x86_64%-[lL]inux.tar.bz2"),
                _.when(platform.is.win_x64, "dhall%-lsp%-server%-.+%-x86_64%-[wW]indows.zip")
            ),
            "Current platform is not supported."
        )
        local find_lsp_server_asset =
            _.compose(_.find_first(_.prop_satisfies(_.matches(asset_name_pattern), "name")), _.prop "assets")

        local repo = "dhall-lang/dhall-haskell"
        ---@type GitHubRelease
        local release = ctx.requested_version
            :map(function(version)
                return github_client.fetch_release(repo, version):and_then(
                    _.if_else(
                        find_lsp_server_asset,
                        Result.success,
                        _.always(Result.failure "Unable to find asset file in GitHub release.")
                    )
                )
            end)
            :or_else_get(function()
                return github_client.fetch_releases(repo):and_then(function(releases)
                    return Optional.of_nilable(_.find_first(find_lsp_server_asset, releases))
                        :ok_or "Unable to find GitHub release."
                end)
            end)
            :get_or_throw "Unable to find GitHub release."

        local asset = find_lsp_server_asset(release)

        platform.when {
            win = function()
                std.download_file(asset.browser_download_url, "dhall-lsp-server.zip")
                std.unzip("dhall-lsp-server.zip", ".")
            end,
            unix = function()
                std.download_file(asset.browser_download_url, "dhall-lsp-server.tar.bz2")
                std.untar "dhall-lsp-server.tar.bz2"
                std.chmod("+x", { path.concat { "bin", "dhall-lsp-server" } })
            end,
        }
        ctx.receipt:with_primary_source {
            type = "github_release_file",
            repo = repo,
            file = asset.browser_download_url,
            release = release.tag_name,
        }

        ctx:link_bin(
            "dhall-lsp-server",
            path.concat { "bin", platform.is.win and "dhall-lsp-server.exe" or "dhall-lsp-server" }
        )
    end,
}
