local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            context.github_release_file("clangd/clangd", function(version)
                return Data.coalesce(
                    Data.when(platform.is_mac, "clangd-mac-%s.zip"),
                    Data.when(platform.is_linux, "clangd-linux-%s.zip"),
                    Data.when(platform.is_win, "clangd-windows-%s.zip")
                ):format(version)
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            function(server, callback, context)
                vim.loop.fs_symlink(
                    path.concat {
                        server.root_dir,
                        ("clangd_%s"):format(context.requested_server_version),
                        "bin",
                        "clangd",
                    },
                    path.concat { server.root_dir, "clangd" },
                    function(err, success)
                        if not success then
                            context.stdio_sink.stderr(tostring(err))
                            callback(false)
                        else
                            callback(true)
                        end
                    end
                )
            end,
        },
        default_options = {
            cmd = { path.concat { root_dir, "clangd" } },
        },
    }
end
