local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.core.platform"
local path = require "nvim-lsp-installer.core.path"
local functional = require "nvim-lsp-installer.core.functional"
local process = require "nvim-lsp-installer.core.process"
local std = require "nvim-lsp-installer.core.managers.std"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://quick-lint-js.com/",
        languages = { "javascript" },
        ---@async
        installer = function()
            local repo = "quick-lint/quick-lint-js"
            local release_file = assert(
                coalesce(
                    when(platform.is.mac_x64, "macos.tar.gz"),
                    when(platform.is.mac_arm64, "macos-aarch64.tar.gz"),
                    when(platform.is.linux_x64, "linux.tar.gz"),
                    when(platform.is.linux_arm64, "linux-aarch64.tar.gz"),
                    when(platform.is.linux_arm, "linux-armhf.tar.gz"),
                    when(platform.is.win_x64, "windows.zip"),
                    when(platform.is.win_arm64, "windows-arm64.zip"),
                    when(platform.is.win_arm, "windows-arm.zip")
                ),
                "Current platform is not supported."
            )

            local source = github.tag { repo = repo }
            source.with_receipt()

            local url = ("https://c.quick-lint-js.com/releases/%s/manual/%s"):format(source.tag, release_file)
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
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
