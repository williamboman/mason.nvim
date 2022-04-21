local server = require "nvim-lsp-installer.server"
local Data = require "nvim-lsp-installer.data"
local a = require "nvim-lsp-installer.core.async"
local platform = require "nvim-lsp-installer.platform"
local github = require "nvim-lsp-installer.core.managers.github"
local spawn = require "nvim-lsp-installer.core.spawn"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "terraform" },
        homepage = "https://github.com/terraform-linters/tflint",
        async = true,
        installer = function()
            github.unzip_release_file({
                repo = "terraform-linters/tflint",
                asset_file = coalesce(
                    when(platform.is_mac and platform.arch == "x64", "tflint_darwin_amd64.zip"),
                    when(platform.is_mac and platform.arch == "arm64", "tflint_darwin_arm64.zip"),
                    when(platform.is_linux and platform.arch == "x64", "tflint_linux_amd64.zip"),
                    when(platform.is_linux and platform.arch == "arm64", "tflint_linux_arm64.zip"),
                    when(platform.is_linux and platform.arch == "x86", "tflint_linux_386.zip"),
                    when(platform.is_win and platform.arch == "x64", "tflint_windows_amd64.zip")
                ),
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
            commands = {
                TFLintInit = {
                    a.scope(function()
                        local notify = require "nvim-lsp-installer.notify"

                        notify "Installing TFLint plugins…"
                        spawn.tflint({
                            "--init",
                            cwd = vim.loop.getcwd(),
                            with_paths = { root_dir },
                        })
                            :on_success(function()
                                if vim.in_fast_event() then
                                    a.scheduler()
                                end
                                notify "Successfully installed TFLint plugins."
                            end)
                            :on_failure(function()
                                if vim.in_fast_event() then
                                    a.scheduler()
                                end
                                notify "Failed to install TFLint plugins."
                            end)
                    end),
                    description = "Runs tflint --init in the current working directory.",
                },
            },
        },
    }
end
