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
            context.use_github_release_file(
                "OmniSharp/omnisharp-roslyn",
                coalesce(
                    when(platform.is_mac, "omnisharp-osx.zip"),
                    when(platform.is_linux and platform.arch == "x64", "omnisharp-linux-x64.zip"),
                    when(
                        platform.is_win,
                        coalesce(
                            when(platform.arch == "x64", "omnisharp-win-x64.zip"),
                            when(platform.arch == "arm64", "omnisharp-win-arm64.zip")
                        )
                    )
                )
            ),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file, "omnisharp")
            end),
            std.chmod("+x", { "omnisharp/run" }),
        },
        default_options = {
            cmd = {
                platform.is_win and path.concat { root_dir, "omnisharp", "OmniSharp.exe" } or path.concat {
                    root_dir,
                    "omnisharp",
                    "run",
                },
                "--languageserver",
                "--hostPID",
                tostring(vim.fn.getpid()),
            },
        },
    }
end
