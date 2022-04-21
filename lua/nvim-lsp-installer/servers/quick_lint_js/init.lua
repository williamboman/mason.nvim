local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"
local std = require "nvim-lsp-installer.core.managers.std"
local github_client = require "nvim-lsp-installer.core.managers.github.client"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://quick-lint-js.com/",
        languages = { "javascript" },
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            local repo = "quick-lint/quick-lint-js"
            local release_file = assert(
                coalesce(
                    when(
                        platform.is_mac,
                        coalesce(
                            when(platform.arch == "x64", "macos.tar.gz"),
                            when(platform.arch == "arm64", "macos-aarch64.tar.gz")
                        )
                    ),
                    when(
                        platform.is_linux,
                        coalesce(
                            when(platform.arch == "x64", "linux.tar.gz"),
                            when(platform.arch == "arm64", "linux-aarch64.tar.gz"),
                            when(platform.arch == "arm", "linux-armhf.tar.gz")
                        )
                    ),
                    when(
                        platform.is_win,
                        coalesce(
                            when(platform.arch == "x64", "windows.zip"),
                            when(platform.arch == "arm64", "windows-arm64.zip"),
                            when(platform.arch == "arm", "windows-arm.zip")
                        )
                    )
                ),
                "Current platform is not supported."
            )
            local version = ctx.requested_version:or_else_get(function()
                return github_client.fetch_latest_tag(repo)
                    :map(function(tag)
                        return tag.name
                    end)
                    :get_or_throw()
            end)
            local url = ("https://c.quick-lint-js.com/releases/%s/manual/%s"):format(version, release_file)
            platform.when {
                unix = function()
                    std.download_file(url, "archive.tar.gz")
                    std.untar("archive.tar.gz", { strip_components = 1 })
                end,
                win = function()
                    std.download_file(url, "archive.zip")
                    std.unzip("archive.zip", ".")
                end,
            }
            ctx.receipt:with_primary_source {
                type = "github_tag",
                repo = repo,
                tag = version,
            }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
