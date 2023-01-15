local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local platform = require "mason-core.platform"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"

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

        local repo = "vala-lang/vala-language-server"
        local source = github.tag { repo = repo }
        source.with_receipt()
        git.clone { ("https://github.com/%s.git"):format(repo), version = Optional.of(source.tag) }

        local install_dir = ctx.cwd:get()
        ctx.spawn.meson { "setup", ("-Dprefix=%s"):format(install_dir), "build" }
        ctx.spawn.meson { "compile", "-C", "build" }
        ctx.spawn.meson { "install", "-C", "build" }
        ctx:link_bin(
            "vala-language-server",
            path.concat { "bin", platform.is.win and "vala-language-server.exe" or "vala-language-server" }
        )
    end,
}
