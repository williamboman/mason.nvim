local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "dockerfile"

return server.Server:new {
    name = "dockerls",
    root_dir = root_dir,
    installer = npm.packages { "dockerfile-language-server-nodejs@latest" },
    default_options = {
        cmd = { npm.executable(root_dir, "docker-langserver"), "--stdio" },
    },
}
