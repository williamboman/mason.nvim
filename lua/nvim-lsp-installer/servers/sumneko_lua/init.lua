local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "lua" },
        homepage = "https://github.com/sumneko/lua-language-server",
        installer = {
            context.use_github_release_file("sumneko/vscode-lua", function(version)
                local target = coalesce(
                    when(
                        platform.is_mac,
                        coalesce(
                            when(platform.arch == "x64", "vscode-lua-%s-darwin-x64.vsix"),
                            when(platform.arch == "arm64", "vscode-lua-%s-darwin-arm64.vsix")
                        )
                    ),
                    when(platform.is_linux and platform.arch == "x64", "vscode-lua-%s-linux-x64.vsix"),
                    when(
                        platform.is_win,
                        coalesce(
                            when(platform.arch == "x64", "vscode-lua-%s-win32-x64.vsix"),
                            when(platform.arch == "x86", "vscode-lua-%s-win32-ia32.vsix")
                        )
                    )
                )

                return target and target:format(version)
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path {
                    path.concat { root_dir, "extension", "server", "bin" },
                },
            },
        },
    }
end
