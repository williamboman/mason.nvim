local path = require "nvim-lsp-installer.path"
local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local context = require "nvim-lsp-installer.installers.context"
local std = require "nvim-lsp-installer.installers.std"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            context.github_release_file(
                "zigtools/zls",
                coalesce(
                    when(platform.is_mac and platform.arch == "x64", "x86_64-macos.tar.xz"),
                    when(
                        platform.is_linux,
                        coalesce(
                            when(platform.arch == "x64", "x86_64-linux.tar.xz"),
                            when(platform.arch == "x86", "i386-linux.tar.zx")
                        )
                    ),
                    when(platform.is_win and platform.arch == "x64", "x86_64-windows.tar.xz")
                )
            ),
            context.capture(function(ctx)
                return std.untarxz_remote(ctx.github_release_file)
            end),
            std.rename("x86_64-windows", "package"),
        },
        default_options = {
            cmd = { path.concat { root_dir, "package", "zls" } },
        },
    }
end
