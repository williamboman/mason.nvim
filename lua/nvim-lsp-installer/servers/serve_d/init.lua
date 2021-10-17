local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/Pure-D/serve-d",
        installer = {
            context.set(function(ctx)
                -- Consider the latest (as of writing) beta release as "latest", instead of 0.6.0.
                -- This is because 1) 0.6.0 is really old, but mostly 2) there are inconcistencies in which assets are
                -- available 0.6.0 vs 0.7.0 beta releases.
                ctx.requested_server_version = Data.coalesce(ctx.requested_server_version, "v0.7.0-beta.7")
            end),
            context.use_github_release_file("Pure-D/serve-d", function(version)
                return Data.coalesce(
                    Data.when(platform.is_mac, "serve-d_%s-osx-x86_64.tar.xz"),
                    Data.when(platform.is_linux, "serve-d_%s-linux-x86_64.tar.xz"),
                    Data.when(platform.is_win, "serve-d_%s-windows-x86_64.zip")
                ):format(version:gsub("^v", ""))
            end),
            context.capture(function(ctx)
                if platform.is_win then
                    return std.unzip_remote(ctx.github_release_file)
                else
                    return std.untarxz_remote(ctx.github_release_file)
                end
            end),
        },
        default_options = {
            cmd = { path.concat { root_dir, "serve-d" } },
        },
    }
end
