local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local target = coalesce(
        when(platform.is_mac, "prosemd-lsp-macos"),
        when(platform.is_linux and platform.arch == "x64", "prosemd-lsp-linux"),
        when(platform.is_win and platform.arch == "x64", "prosemd-lsp-windows.exe")
    )

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/kitten/prosemd-lsp",
        languages = { "markdown" },
        installer = {
            context.use_github_release_file("kitten/prosemd-lsp", target),
            context.capture(function(ctx)
                return std.download_file(
                    ctx.github_release_file,
                    platform.is_win and "prosemd-lsp.exe" or "prosemd-lsp"
                )
            end),
            std.chmod("+x", { "prosemd-lsp" }),
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
