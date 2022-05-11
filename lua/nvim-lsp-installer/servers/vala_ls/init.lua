local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local std = require "nvim-lsp-installer.core.managers.std"
local github = require "nvim-lsp-installer.core.managers.github"
local process = require "nvim-lsp-installer.core.process"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://wiki.gnome.org/Projects/Vala",
        languages = { "vala" },
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable("meson", { help_url = "https://mesonbuild.com/Getting-meson.html" })
            std.ensure_executable("ninja", { help_url = "https://ninja-build.org/" })
            std.ensure_executable("valac", { help_url = "https://wiki.gnome.org/Projects/Vala" })

            local release_source = github.untarxz_release_file {
                repo = "Prince781/vala-language-server",
                asset_file = function(version)
                    return ("vala-language-server-%s.tar.xz"):format(version)
                end,
            }
            release_source.with_receipt()

            local vala_dirname = ("vala-language-server-%s"):format(release_source.release)
            local install_dir = ctx.cwd:get()
            ctx:chdir(vala_dirname, function()
                ctx.spawn.meson { ("-Dprefix=%s"):format(install_dir), "build" }
                ctx.spawn.ninja { "-C", "build", "install" }
            end)
            ctx.fs:rmrf(vala_dirname)
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
