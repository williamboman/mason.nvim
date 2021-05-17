local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("vim")

return server.Server:new {
    name = "vimls",
    root_dir = root_dir,
    installer = npm.packages { "vim-language-server@latest" },
    default_options = {
        cmd = { path.concat { root_dir, "node_modules", ".bin", "vim-language-server" }, "--stdio" },
    }
}
