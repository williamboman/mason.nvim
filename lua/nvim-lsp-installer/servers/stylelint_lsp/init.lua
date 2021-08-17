local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "stylelint_lsp"

return server.Server:new {
    name = "stylelint_lsp",
    root_dir = root_dir,
    installer = npm.packages { "stylelint-lsp" },
    default_options = {
        cmd = { npm.executable(root_dir, "stylelint-lsp"), "--stdio" },
    },
}
