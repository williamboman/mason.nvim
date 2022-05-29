local a = require "nvim-lsp-installer.core.async"
local notify = require "nvim-lsp-installer.notify"
local spawn = require "nvim-lsp-installer.core.spawn"
local process = require "nvim-lsp-installer.core.process"
local server = require "nvim-lsp-installer.server"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local github = require "nvim-lsp-installer.core.managers.github"
local middleware = require "nvim-lsp-installer.middleware"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    middleware.register_server_hook(name, function()
        vim.api.nvim_create_user_command(
            "TFLintInit",
            a.scope(function()
                notify "Installing TFLint plugins…"
                local result = spawn.tflint {
                    "--init",
                    cwd = vim.loop.cwd(),
                    stdio_sink = process.simple_sink(),
                    with_paths = { root_dir },
                }
                if vim.in_fast_event() then
                    a.scheduler()
                end
                result
                    :on_success(function()
                        notify "Successfully installed TFLint plugins."
                    end)
                    :on_failure(function()
                        notify("Failed to install TFLint plugins.", vim.log.levels.ERROR)
                    end)
            end),
            {
                desc = "[nvim-lsp-installer] Runs tflint --init in the current directory.",
            }
        )
    end)

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "terraform" },
        homepage = "https://github.com/terraform-linters/tflint",
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
        },
    }
end
