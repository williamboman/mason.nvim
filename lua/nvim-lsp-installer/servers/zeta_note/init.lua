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
        homepage = "https://github.com/artempyanykh/zeta-note",
        languages = { "markdown" },
        installer = {
            context.use_github_release_file(
                "artempyanykh/zeta-note",
                coalesce(
                    when(platform.is_mac, "zeta-note-macos"),
                    when(platform.is_linux and platform.arch == "x64", "zeta-note-linux"),
                    when(platform.is_win and platform.arch == "x64", "zeta-note-windows.exe")
                )
            ),
            context.capture(function(ctx)
                return std.download_file(ctx.github_release_file, platform.is_win and "zeta-note.exe" or "zeta-note")
            end),
            std.chmod("+x", { "zeta-note" }),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd = { "zeta-note" },
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
