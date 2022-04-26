local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/hashicorp/terraform-ls",
        languages = { "terraform" },
        async = true,
        installer = function()
            github.unzip_release_file({
                repo = "hashicorp/terraform-ls",
                asset_file = function(version)
                    local target = coalesce(
                        when(
                            platform.is_mac,
                            coalesce(
                                when(platform.arch == "arm64", "terraform-ls_%s_darwin_arm64.zip"),
                                when(platform.arch == "x64", "terraform-ls_%s_darwin_amd64.zip")
                            )
                        ),
                        when(
                            platform.is_linux,
                            coalesce(
                                when(platform.arch == "arm64", "terraform-ls_%s_linux_arm64.zip"),
                                when(platform.arch == "arm", "terraform-ls_%s_linux_arm.zip"),
                                when(platform.arch == "x64", "terraform-ls_%s_linux_amd64.zip")
                            )
                        ),
                        when(
                            platform.is_win,
                            coalesce(when(platform.arch == "x64", "terraform-ls_%s_windows_amd64.zip"))
                        )
                    )
                    return target and target:format(version:gsub("^v", ""))
                end,
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
