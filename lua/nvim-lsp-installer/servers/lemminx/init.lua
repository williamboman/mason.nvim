local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local file = coalesce(
        when(platform.is_mac, "lemminx-osx-x86_64.zip"),
        when(platform.is_linux, "lemminx-linux.zip"),
        when(platform.is_win, "lemminx-win32.zip")
    )
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            function(_, callback, ctx)
                if not file then
                    ctx.stdio_sink.stderr(
                        ("Your operating system or architecture (%q) is not yet supported."):format(platform.arch)
                    )
                    callback(false)
                else
                    callback(true)
                end
            end,
            context.set(function(ctx)
                ctx.requested_server_version = coalesce(ctx.requested_server_version, "0.18.0-400")
            end),
            context.capture(function(ctx)
                return std.unzip_remote(
                    ("https://download.jboss.org/jbosstools/vscode/stable/lemminx-binary/%s/%s"):format(
                        ctx.requested_server_version,
                        file
                    )
                )
            end),
            function(server, callback, ctx)
                local unzipped_file = file:gsub(".zip$", "")
                local old_path = path.concat { server.root_dir, unzipped_file }
                local new_path = path.concat { server.root_dir, platform.is_win and "lemminx.exe" or "lemminx" }
                ctx.stdio_sink.stdout(("Renaming %q to %q."):format(old_path, new_path))
                local ok, result = pcall(fs.rename, old_path, new_path)
                callback(ok and result)
            end,
        },
        default_options = {
            cmd = { path.concat { root_dir, "lemminx" } },
        },
    }
end
