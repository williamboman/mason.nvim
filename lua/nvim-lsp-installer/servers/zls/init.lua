local path = require "nvim-lsp-installer.path"
local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local context = require "nvim-lsp-installer.installers.context"
local std = require "nvim-lsp-installer.installers.std"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local archive_name = coalesce(
        when(platform.is_mac and platform.arch == "x64", "x86_64-macos"),
        when(
            platform.is_linux,
            coalesce(when(platform.arch == "x64", "x86_64-linux"), when(platform.arch == "x86", "i386-linux.tar.zx"))
        ),
        when(platform.is_win and platform.arch == "x64", "x86_64-windows")
    )

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/zigtools/zls",
        languages = { "zig" },
        installer = {
            context.use_github_release_file("zigtools/zls", archive_name and ("%s.tar.xz"):format(archive_name)),
            context.capture(function(ctx)
                return std.untarxz_remote(ctx.github_release_file)
            end),
            std.rename("bin", "package"),
        },
        default_options = {
            cmd = { path.concat { root_dir, "package", "zls" } },
        },
    }
end
