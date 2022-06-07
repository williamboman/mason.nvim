local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/artempyanykh/marksman",
        languages = { "markdown" },
        installer = function()
            github.download_release_file({
                repo = "artempyanykh/marksman",
                out_file = platform.is_win and "marksman.exe" or "marksman",
                asset_file = coalesce(
                    when(platform.is.mac, "marksman-macos"),
                    when(platform.is.linux_x64, "marksman-linux"),
                    when(platform.is_win_x64, "marksman.exe")
                ),
            }).with_receipt()
            std.chmod("+x", { "marksman" })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
