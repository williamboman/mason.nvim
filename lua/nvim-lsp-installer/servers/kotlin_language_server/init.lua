local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = std.unzip_remote "https://github.com/fwcd/kotlin-language-server/releases/latest/download/server.zip",
        default_options = {
            cmd = {
                path.concat {
                    root_dir,
                    "server",
                    "bin",
                    platform.is_win and "kotlin-language-server.bat" or "kotlin-language-server",
                },
            },
        },
    }
end
