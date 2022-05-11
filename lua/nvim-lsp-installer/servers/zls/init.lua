local path = require "nvim-lsp-installer.core.path"
local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local process = require "nvim-lsp-installer.core.process"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/zigtools/zls",
        languages = { "zig" },
        ---@param ctx InstallContext
        installer = function(ctx)
            local asset_file = coalesce(
                when(platform.is_mac, "x86_64-macos.tar.xz"),
                when(
                    platform.is_linux,
                    coalesce(
                        when(platform.arch == "x64", "x86_64-linux.tar.xz"),
                        when(platform.arch == "x86", "i386-linux.tar.xz")
                    )
                ),
                when(platform.is_win and platform.arch == "x64", "x86_64-windows.tar.xz")
            )
            github.untarxz_release_file({
                repo = "zigtools/zls",
                asset_file = asset_file,
            }).with_receipt()
            ctx.fs:rename("bin", "package")
            std.chmod("+x", { path.concat { "package", "zls" } })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "package" } },
            },
        },
    }
end
