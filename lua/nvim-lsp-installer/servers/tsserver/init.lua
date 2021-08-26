local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "tsserver"

return server.Server:new {
    name = "tsserver",
    root_dir = root_dir,
    installer = npm.packages { "typescript", "typescript-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "typescript-language-server"), "--stdio" },
    },
}
