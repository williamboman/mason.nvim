local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"

local root_dir = server.get_server_root_path "groovyls"

return server.Server:new {
    name = "groovyls",
    root_dir = root_dir,
    installer = {
        std.ensure_executables { { "javac", "javac was not found in path." } },
        std.git_clone "https://github.com/GroovyLanguageServer/groovy-language-server",
        std.gradlew {
            args = { "build" },
        },
    },
    default_options = {
        cmd = { "java", "-jar", path.concat { root_dir, "build", "libs", "groovyls-all.jar" } },
    },
}
