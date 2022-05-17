local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.core.platform"
local path = require "nvim-lsp-installer.core.path"
local functional = require "nvim-lsp-installer.core.functional"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"
local Result = require "nvim-lsp-installer.core.result"

local coalesce, when = functional.coalesce, functional.when

---@param install_dir string
---@param use_mono boolean
local generate_cmd = function(install_dir, use_mono)
    if use_mono then
        return {
            "mono",
            path.concat { install_dir, "omnisharp-mono", "OmniSharp.exe" },
            "--languageserver",
            "--hostPID",
            tostring(vim.fn.getpid()),
        }
    else
        return {
            "dotnet",
            path.concat { install_dir, "omnisharp", "OmniSharp.dll" },
            "--languageserver",
            "--hostPID",
            tostring(vim.fn.getpid()),
        }
    end
end

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/OmniSharp/omnisharp-roslyn",
        languages = { "c#" },
        ---@param ctx InstallContext
        installer = function(ctx)
            Result.run_catching(function()
                std.ensure_executable("mono", { help_url = "https://www.mono-project.com/download/stable/" })
            end):recover(function()
                std.ensure_executable("dotnet", { help_url = "https://dotnet.microsoft.com/download" })
            end)

            ctx.fs:mkdir "omnisharp"
            ctx:chdir("omnisharp", function()
                github.unzip_release_file {
                    repo = "OmniSharp/omnisharp-roslyn",
                    asset_file = coalesce(
                        when(platform.is.mac_x64, "omnisharp-osx-x64-net6.0.zip"),
                        when(platform.is.mac_arm64, "omnisharp-osx-arm64-net6.0.zip"),
                        when(platform.is.linux_x64, "omnisharp-linux-x64-net6.0.zip"),
                        when(platform.is.linux_arm64, "omnisharp-linux-arm64-net6.0.zip"),
                        when(platform.is.win_x64, "omnisharp-win-x64-net6.0.zip"),
                        when(platform.is.win_arm64, "omnisharp-win-arm64-net6.0.zip")
                    ),
                }
            end)

            ctx.fs:mkdir "omnisharp-mono"
            ctx:chdir("omnisharp-mono", function()
                github.unzip_release_file({
                    repo = "OmniSharp/omnisharp-roslyn",
                    asset_file = "omnisharp-mono.zip",
                }).with_receipt()
            end)
        end,
        default_options = {
            on_new_config = function(config)
                config.cmd = generate_cmd(root_dir, config.use_mono)
            end,
        },
    }
end
