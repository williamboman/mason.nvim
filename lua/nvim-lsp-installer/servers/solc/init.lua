local server = require "nvim-lsp-installer.server"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local process = require "nvim-lsp-installer.core.process"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/ethereum/solidity",
        languages = { "solidity" },
        installer = function()
            github.download_release_file({
                repo = "ethereum/solidity",
                out_file = platform.is_win and "solc.exe" or "solc",
                asset_file = coalesce(
                    when(platform.is_mac, "solc-macos"),
                    when(platform.is_linux, "solc-static-linux"),
                    when(platform.is_win, "solc-windows.exe")
                ),
            }).with_receipt()
            std.chmod("+x", { "solc" })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
