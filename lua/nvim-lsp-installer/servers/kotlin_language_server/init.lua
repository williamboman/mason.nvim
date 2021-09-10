local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"

local root_dir = server.get_server_root_path "kotlin"

return server.Server:new {
    name = "kotlin_language_server",
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
