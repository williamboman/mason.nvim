local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local unzipped_file = coalesce(
        when(platform.is_mac, "lemminx-osx-x86_64"),
        when(platform.is_linux, "lemminx-linux"),
        when(platform.is_win, "lemminx-win32")
    )

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "xml" },
        homepage = "https://github.com/eclipse/lemminx",
        installer = {
            function(_, callback, ctx)
                if not unzipped_file then
                    ctx.stdio_sink.stderr(
                        ("Your operating system or architecture (%q) is not yet supported."):format(platform.arch)
                    )
                    callback(false)
                else
                    callback(true)
                end
            end,
            context.set(function(ctx)
                ctx.requested_server_version = coalesce(ctx.requested_server_version, "LATEST")
            end),
            context.capture(function(ctx)
                return std.unzip_remote(
                    ("https://download.jboss.org/jbosstools/vscode/snapshots/lemminx-binary/%s/%s.zip"):format(
                        ctx.requested_server_version,
                        unzipped_file
                    )
                )
            end),
            std.rename(
                platform.is_win and ("%s.exe"):format(unzipped_file) or unzipped_file,
                platform.is_win and "lemminx.exe" or "lemminx"
            ),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
