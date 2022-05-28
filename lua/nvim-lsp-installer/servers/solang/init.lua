local server = require "nvim-lsp-installer.server"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local process = require "nvim-lsp-installer.core.process"
local std = require "nvim-lsp-installer.core.managers.std"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://solang.readthedocs.io/en/latest/",
        languages = { "solidity" },
        ---@async
        installer = function()
            local source = github.download_release_file({
                repo = "hyperledger-labs/solang",
                out_file = platform.is.win and "solang.exe" or "solang",
                asset_file = coalesce(
                    when(platform.is.mac_x64, "solang-mac-intel"),
                    when(platform.is.mac_arm64, "solang-mac-arm"),
                    when(platform.is.linux_arm64, "solang-linux-arm64"),
                    when(platform.is.linux_x64, "solang-linux-x86-64"),
                    when(platform.is.win_x64, "solang.exe")
                ),
            }).with_receipt()
            std.chmod("+x", { "solang" })
            return source
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
