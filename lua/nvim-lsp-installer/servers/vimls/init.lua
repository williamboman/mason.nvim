local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "vim"

return server.Server:new {
    name = "vimls",
    root_dir = root_dir,
    installer = npm.packages { "vim-language-server@latest" },
    default_options = {
        cmd = { npm.executable(root_dir, "vim-language-server"), "--stdio" },
    },
}
