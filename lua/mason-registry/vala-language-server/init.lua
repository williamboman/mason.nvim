local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local platform = require "mason-core.platform"
local path = require "mason-core.path"

return Pkg.new {
    name = "vala-language-server",
    desc = [[Code Intelligence for Vala & Genie]],
    homepage = "https://github.com/vala-lang/vala-language-server",
    languages = { Pkg.Lang.Vala },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable("meson", { help_url = "https://mesonbuild.com/Getting-meson.html" })
        std.ensure_executable("ninja", { help_url = "https://ninja-build.org/" })
        std.ensure_executable("valac", { help_url = "https://wiki.gnome.org/Projects/Vala" })

        local release_source = github.untarxz_release_file {
            repo = "vala-lang/vala-language-server",
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
        ctx:link_bin(
            "vala-language-server",
            path.concat { "bin", platform.is.win and "vala-language-server.exe" or "vala-language-server" }
        )
    end,
}
