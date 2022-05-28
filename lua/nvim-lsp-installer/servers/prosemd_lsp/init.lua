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
        homepage = "https://github.com/kitten/prosemd-lsp",
        languages = { "markdown" },
        installer = function()
            github.download_release_file({
                repo = "kitten/prosemd-lsp",
                out_file = platform.is_win and "prosemd-lsp.exe" or "prosemd-lsp",
                asset_file = coalesce(
                    when(platform.is_mac, "prosemd-lsp-macos"),
                    when(platform.is_linux and platform.arch == "x64", "prosemd-lsp-linux"),
                    when(platform.is_win and platform.arch == "x64", "prosemd-lsp-windows.exe")
                ),
            }).with_receipt()
            std.chmod("+x", { "prosemd-lsp" })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
