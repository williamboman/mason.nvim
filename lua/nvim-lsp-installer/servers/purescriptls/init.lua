local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "purescript"

return server.Server:new {
    name = "purescriptls",
    root_dir = root_dir,
    installer = npm.packages { "purescript-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "purescript-language-server"), "--stdio" },
    },
}
