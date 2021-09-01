local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local platform = require "nvim-lsp-installer.platform"
local shell = require "nvim-lsp-installer.installers.shell"

local root_dir = server.get_server_root_path "kotlin"

return server.Server:new {
    name = "kotlin_language_server",
    root_dir = root_dir,
    installer = installers.when {
        unix = shell.bash [[
        wget -O server.zip https://github.com/fwcd/kotlin-language-server/releases/latest/download/server.zip;
        unzip server.zip;
        rm server.zip;
        ]],
        win = shell.cmd [[ curl -fLo server.zip https://github.com/fwcd/kotlin-language-server/releases/latest/download/server.zip && tar -xvf server.zip && del /f server.zip ]],
    },
    default_options = {
        cmd = {
            path.concat {
                root_dir,
                "server",
                "bin",
                platform.is_win() and "kotlin-language-server.bat" or "kotlin-language-server",
            },
        },
    },
}
