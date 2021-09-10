local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "dotls"

return server.Server:new {
    name = "dotls",
    root_dir = root_dir,
    installer = npm.packages { "dot-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "dot-language-server"), "--stdio" },
    },
}
