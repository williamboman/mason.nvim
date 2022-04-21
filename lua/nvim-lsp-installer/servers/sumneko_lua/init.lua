local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "lua" },
        homepage = "https://github.com/sumneko/lua-language-server",
        async = true,
        installer = function()
            github.unzip_release_file({
                repo = "sumneko/vscode-lua",
                asset_file = function(version)
                    local target = coalesce(
                        when(
                            platform.is_mac,
                            coalesce(
                                when(platform.arch == "x64", "vscode-lua-%s-darwin-x64.vsix"),
                                when(platform.arch == "arm64", "vscode-lua-%s-darwin-arm64.vsix")
                            )
                        ),
                        when(
                            platform.is_linux,
                            coalesce(
                                when(platform.arch == "x64", "vscode-lua-%s-linux-x64.vsix"),
                                when(platform.arch == "arm64", "vscode-lua-%s-linux-arm64.vsix")
                            )
                        ),
                        when(
                            platform.is_win,
                            coalesce(
                                when(platform.arch == "x64", "vscode-lua-%s-win32-x64.vsix"),
                                when(platform.arch == "x86", "vscode-lua-%s-win32-ia32.vsix")
                            )
                        )
                    )

                    return target and target:format(version)
                end,
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path {
                    path.concat { root_dir, "extension", "server", "bin" },
                },
            },
        },
    }
end
