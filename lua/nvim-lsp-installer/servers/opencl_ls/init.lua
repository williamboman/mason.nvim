local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/Galarius/opencl-language-server",
        languages = { "opencl" },
        installer = {
            context.use_github_release_file(
                "Galarius/opencl-language-server",
                coalesce(
                    when(platform.is_mac, "opencl-language-server-darwin-x86_64.tar.gz"),
                    when(platform.is_linux and platform.arch == "x64", "opencl-language-server-linux-x86_64.tar.gz"),
                    when(platform.is_win and platform.arch == "x64", "opencl-language-server-win32-x86_64.zip")
                )
            ),
            context.capture(coalesce(
                when(platform.is_unix, function(ctx)
                    return std.untargz_remote(ctx.github_release_file)
                end),
                when(platform.is_win, function(ctx)
                    return std.unzip_remote(ctx.github_release_file)
                end)
            )),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
