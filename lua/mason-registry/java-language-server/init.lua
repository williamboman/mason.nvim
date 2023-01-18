local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local github = require "mason-core.managers.github"
local git = require "mason-core.managers.git"
local platform = require "mason-core.platform"
local path = require "mason-core.path"
local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"

local coalesce, when = _.coalesce, _.when

local function build(ctx)
    local link_script = coalesce(
        when(platform.is.linux, "scripts/link_linux.sh"),
        when(platform.is.mac, "scripts/link_mac.sh"),
        when(platform.is.win, "scripts/link_win.sh")
    )

    ctx.spawn.sh { link_script }
    ctx.spawn.mvn { "package", "-DskipTests" }
end

local function get_path(ctx)
    local launch_script = coalesce(
        when(platform.is.linux, "launch_linux.sh"),
        when(platform.is.mac, "launch_mac.sh"),
        when(platform.is.win, "launch_win.sh")
    )

    return path.concat {
        ctx.package:get_install_path(),
        "dist",
        launch_script,
    }
end

return Pkg.new {
    name = "java-language-server",
    desc = [[Java language server using the Java compiler API]],
    homepage = "https://github.com/georgewfraser/java-language-server",
    languages = { Pkg.Lang.Java },
    categories = { Pkg.Cat.LSP },
    --@async
    --@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable("mvn", {
            help_url = "https://maven.apache.org/download.cgi",
        })

        local source = github.tag { repo = "georgewfraser/java-language-server" }
        source.with_receipt()
        git.clone {
            "https://github.com/georgewfraser/java-language-server",
            version = Optional.of(source.tag),
        }

        build(ctx)
        ctx:link_bin(
            "java-language-server",
            ctx:write_shell_exec_wrapper("java-language-server", ("%q org.javacs.Main"):format(get_path(ctx)))
        )
    end,
}
