local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.installers.go"

local root_dir = server.get_server_root_path "sqls"

return server.Server:new {
    name = "sqls",
    root_dir = root_dir,
    installer = go.packages { "github.com/lighttiger2505/sqls" },
    default_options = {
        cmd = { go.executable(root_dir, "sqls") },
    },
}
