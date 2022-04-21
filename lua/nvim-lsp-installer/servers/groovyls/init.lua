local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.core.managers.std"
local git = require "nvim-lsp-installer.core.managers.git"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "groovy" },
        homepage = "https://github.com/GroovyLanguageServer/groovy-language-server",
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable "javac"
            git.clone({ "https://github.com/GroovyLanguageServer/groovy-language-server" }).with_receipt()
            ctx:promote_cwd()
            ctx.spawn.gradlew {
                "build",
                with_paths = { ctx.cwd:get() },
            }
        end,
        default_options = {
            cmd = { "java", "-jar", path.concat { root_dir, "build", "libs", "groovyls-all.jar" } },
        },
    }
end
