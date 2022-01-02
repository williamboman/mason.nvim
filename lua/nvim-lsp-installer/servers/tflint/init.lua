local server = require "nvim-lsp-installer.server"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local os = coalesce(
        when(platform.is_mac, "darwin"),
        when(platform.is_linux, "linux"),
        when(platform.is_win, "windows")
    )

    local arch = coalesce(when(platform.arch == "x64", "amd64"), platform.arch)

    local target = ("tflint_%s_%s.zip"):format(os, arch)

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "terraform" },
        homepage = "https://github.com/terraform-linters/tflint",
        installer = {
            context.use_github_release_file("terraform-linters/tflint", target),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
            commands = {
                TFLintInit = {
                    function()
                        local process = require "nvim-lsp-installer.process"
                        local notify = require "nvim-lsp-installer.notify"
                        local path = require "nvim-lsp-installer.path"

                        notify "Installing TFLint plugins…"
                        process.spawn(
                            "tflint",
                            {
                                args = { "--init" },
                                cwd = path.cwd(),
                                stdio_sink = process.simple_sink(),
                                env = process.graft_env {
                                    PATH = process.extend_path { root_dir },
                                },
                            },
                            vim.schedule_wrap(function(success)
                                if success then
                                    notify "Successfully installed TFLint plugins."
                                else
                                    notify "Failed to install TFLint plugins."
                                end
                            end)
                        )
                    end,
                    description = "Runs tflint --init in the current working directory.",
                },
            },
        },
    }
end
