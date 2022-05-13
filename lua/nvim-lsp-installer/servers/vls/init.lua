local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local github = require "nvim-lsp-installer.core.managers.github"
local github_client = require "nvim-lsp-installer.core.managers.github.client"
local std = require "nvim-lsp-installer.core.managers.std"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local Optional = require "nvim-lsp-installer.core.optional"
local process = require "nvim-lsp-installer.core.process"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/vlang/vls",
        languages = { "vlang", "V" },
        ---@async
        installer = function()
            local repo = "vlang/vls"

            ---@type GitHubRelease
            local latest_dev_build =
                github_client.fetch_latest_release(repo, { include_prerelease = true }):get_or_throw()

            local source = github.release_file {
                version = Optional.of(latest_dev_build.tag_name),
                repo = repo,
                asset_file = functional.coalesce(
                    functional.when(platform.is.linux_x64, "vls_linux_x64"),
                    functional.when(platform.is.mac, "vls_macos_x64"),
                    functional.when(platform.is.win_x64, "vls_windows_x64.exe")
                ),
            }
            source.with_receipt()
            std.download_file(source.download_url, platform.is.win and "vls.exe" or "vls")
            std.chmod("+x", { "vls" })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
