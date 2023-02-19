local Pkg = require "mason-core.package"
local std = require "mason-core.managers.std"
local git = require "mason-core.managers.git"
local path = require "mason-core.path"

return Pkg.new {
    name = "groovy-language-server",
    desc = [[A language server for Groovy]],
    homepage = "https://github.com/GroovyLanguageServer/groovy-language-server",
    languages = { Pkg.Lang.Groovy },
    categories = { Pkg.Cat.LSP },
    ---@async
    ---@param ctx InstallContext
    install = function(ctx)
        std.ensure_executable "javac"
        git.clone({ "https://github.com/GroovyLanguageServer/groovy-language-server" }).with_receipt()
        ctx:promote_cwd()
        ctx.spawn.gradlew {
            "build",
            with_paths = { ctx.cwd:get() },
        }

        ctx:link_bin(
            "groovy-language-server",
            ctx:write_shell_exec_wrapper(
                "groovy-language-server",
                ("java -jar %q"):format(
                    path.concat { ctx.package:get_install_path(), "build", "libs", "groovy-language-server-all.jar" }
                )
            )
        )
    end,
}
