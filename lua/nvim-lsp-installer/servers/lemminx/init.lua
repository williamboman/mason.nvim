local server = require "nvim-lsp-installer.server"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local process = require "nvim-lsp-installer.core.process"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "xml" },
        homepage = "https://github.com/eclipse/lemminx",
        ---@param ctx InstallContext
        installer = function(ctx)
            local unzipped_file = assert(
                coalesce(
                    when(platform.is_mac, "lemminx-osx-x86_64"),
                    when(platform.is_linux, "lemminx-linux"),
                    when(platform.is_win, "lemminx-win32")
                ),
                ("Your operating system or architecture (%q) is not yet supported."):format(platform.arch)
            )

            std.download_file(
                ("https://download.jboss.org/jbosstools/vscode/snapshots/lemminx-binary/%s/%s.zip"):format(
                    ctx.requested_version:or_else "0.19.2-655", -- TODO: resolve latest version dynamically
                    unzipped_file
                ),
                "lemminx.zip"
            )
            std.unzip("lemminx.zip", ".")
            ctx.fs:rename(
                platform.is_win and ("%s.exe"):format(unzipped_file) or unzipped_file,
                platform.is_win and "lemminx.exe" or "lemminx"
            )
            ctx.receipt:with_primary_source(ctx.receipt.unmanaged)
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
