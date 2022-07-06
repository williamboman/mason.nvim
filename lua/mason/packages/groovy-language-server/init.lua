local Pkg = require "mason.core.package"
local std = require "mason.core.managers.std"
local git = require "mason.core.managers.git"

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
    end,
}
