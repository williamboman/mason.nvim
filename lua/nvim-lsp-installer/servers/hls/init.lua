local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.core.managers.std"
local github_client = require "nvim-lsp-installer.core.managers.github.client"
local path = require "nvim-lsp-installer.path"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://haskell-language-server.readthedocs.io/en/latest/",
        languages = { "haskell" },
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            local repo = "haskell/haskell-language-server"
            local release = ctx.requested_version:or_else_get(function()
                return github_client.fetch_latest_release(repo)
                    :map(
                        ---@param release GitHubRelease
                        function(release)
                            return release.tag_name
                        end
                    )
                    :get_or_throw()
            end)

            local asset_file = coalesce(
                when(platform.is.mac_arm64, "haskell-language-server-%s-aarch64-darwin.tar.xz"),
                when(platform.is.mac_x64, "haskell-language-server-%s-x86_64-darwin.tar.xz"),
                when(platform.is.win_x64, "haskell-language-server-%s-x86_64-unknown-mingw32.zip")
            )

            if not asset_file and platform.is_linux then
                asset_file = std.select({
                    "haskell-language-server-%s-aarch64-linux-deb10.tar.xz",
                    "haskell-language-server-%s-x86_64-linux-centos7.tar.xz",
                    "haskell-language-server-%s-x86_64-linux-deb10.tar.xz",
                    "haskell-language-server-%s-x86_64-linux-deb9.tar.xz",
                    "haskell-language-server-%s-x86_64-linux-fedora27.tar.xz",
                }, {
                    prompt = "[hls] Unable to determine which distribution to download, please select one.",
                    format_item = function(item)
                        return item:format(release)
                    end,
                })
            end

            assert(asset_file, "Couldn't determine which archive to download.")

            local download_url = ("https://downloads.haskell.org/~hls/haskell-language-server-%s/%s"):format(
                release,
                asset_file:format(release)
            )

            platform.when {
                unix = function()
                    std.download_file(download_url, "haskell-language-server.tar.xz")
                    std.untarxz("haskell-language-server.tar.xz", { strip_components = 1 })
                end,
                win = function()
                    std.download_file(download_url, "haskell-language-server.zip")
                    std.unzip("haskell-language-server.zip", ".")
                end,
            }

            ctx.receipt:with_primary_source(ctx.receipt.github_release(repo, release))
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path {
                    platform.is_win and root_dir or path.concat { root_dir, "bin" },
                },
            },
        },
    }
end
