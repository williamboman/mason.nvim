local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local github = require "nvim-lsp-installer.core.managers.github"
local functional = require "nvim-lsp-installer.core.functional"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/hirosystems/clarity-lsp",
        languages = { "clarity" },
        installer = function()
            github.unzip_release_file({
                repo = "hirosystems/clarity-lsp",
                asset_file = coalesce(
                    when(platform.is_mac, "clarity-lsp-macos-x64.zip"),
                    when(platform.is_linux and platform.arch == "x64", "clarity-lsp-linux-x64.zip"),
                    when(platform.is_win and platform.arch == "x64", "clarity-lsp-windows-x64.zip")
                ),
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
