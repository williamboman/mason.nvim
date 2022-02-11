local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/OmniSharp/omnisharp-roslyn",
        languages = { "c#" },
        installer = {
            std.ensure_executables {
                {
                    "dotnet",
                    "dotnet was not found in path. Refer to https://dotnet.microsoft.com/download for installation instructions.",
                },
            },
            context.use_github_release_file(
                "OmniSharp/omnisharp-roslyn",
                coalesce(
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
                )
            ),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file, "omnisharp")
            end),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
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
