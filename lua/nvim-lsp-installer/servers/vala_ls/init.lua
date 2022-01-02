local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local installers = require "nvim-lsp-installer.installers"
local process = require "nvim-lsp-installer.process"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://wiki.gnome.org/Projects/Vala",
        languages = { "vala" },
        installer = {
            std.ensure_executables {
                { "meson", "meson was not found in path. Refer to https://mesonbuild.com/Getting-meson.html" },
                { "ninja", "ninja was not found in path. Refer to https://ninja-build.org/" },
                { "valac", "valac was not found in path. Refer to https://wiki.gnome.org/Projects/Vala" },
            },
            context.use_github_release_file("Prince781/vala-language-server", function(version)
                return ("vala-language-server-%s.tar.xz"):format(version)
            end),
            context.capture(function(ctx)
                return installers.pipe {
                    std.untarxz_remote(ctx.github_release_file),
                    std.rename(
                        ("vala-language-server-%s"):format(ctx.requested_server_version),
                        "vala-language-server"
                    ),
                }
            end),
            function(_, callback, ctx)
                local c = process.chain {
                    cwd = path.concat { ctx.install_dir, "vala-language-server" },
                    stdio_sink = ctx.stdio_sink,
                }

                c.run("meson", { ("-Dprefix=%s"):format(ctx.install_dir), "build" })
                c.run("ninja", { "-C", "build", "install" })

                c.spawn(callback)
            end,
            std.rmrf "vala-language-server",
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
