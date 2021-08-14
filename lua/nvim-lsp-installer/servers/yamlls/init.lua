local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "yaml"

return server.Server:new {
    name = "yamlls",
    root_dir = root_dir,
    installer = npm.packages { "yaml-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "yaml-language-server"), "--stdio" },
    },
}
