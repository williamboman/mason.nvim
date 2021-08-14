local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "sqlls"

return server.Server:new {
    name = "sqlls",
    root_dir = root_dir,
    installer = npm.packages { "sql-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "sql-language-server") },
    },
}
