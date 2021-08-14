local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "vuels"

return server.Server:new {
    name = "vuels",
    root_dir = root_dir,
    installer = npm.packages { "vls" },
    default_options = {
        cmd = { npm.executable(root_dir, "vls"), "--stdio" },
    },
}
