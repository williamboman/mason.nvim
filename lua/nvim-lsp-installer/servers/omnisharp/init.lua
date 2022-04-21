local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/OmniSharp/omnisharp-roslyn",
        languages = { "c#" },
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable("dotnet", { help_url = "https://dotnet.microsoft.com/download" })

            -- We write to the omnisharp directory for backwards compatibility reasons
            ctx.fs:mkdir "omnisharp"
            ctx:chdir("omnisharp", function()
                github.unzip_release_file({
                    repo = "OmniSharp/omnisharp-roslyn",
                    asset_file = coalesce(
                        when(
                            platform.is_mac,
                            coalesce(
                                when(platform.arch == "x64", "omnisharp-osx-x64-net6.0.zip"),
                                when(platform.arch == "arm64", "omnisharp-osx-arm64-net6.0.zip")
                            )
                        ),
                        when(
                            platform.is_linux,
                            coalesce(
                                when(platform.arch == "x64", "omnisharp-linux-x64-net6.0.zip"),
                                when(platform.arch == "arm64", "omnisharp-linux-arm64-net6.0.zip")
                            )
                        ),
                        when(
                            platform.is_win,
                            coalesce(
                                when(platform.arch == "x64", "omnisharp-win-x64-net6.0.zip"),
                                when(platform.arch == "arm64", "omnisharp-win-arm64-net6.0.zip")
                            )
                        )
                    ),
                }).with_receipt()
            end)
        end,
        default_options = {
            cmd = {
                "dotnet",
                path.concat { root_dir, "omnisharp", "OmniSharp.dll" },
                "--languageserver",
                "--hostPID",
                tostring(vim.fn.getpid()),
            },
        },
    }
end
