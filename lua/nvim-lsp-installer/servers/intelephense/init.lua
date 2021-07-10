local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("php")

return server.Server:new {
    name = "intelephense",
    root_dir = root_dir,
    installer = npm.packages { "intelephense" },
    default_options = {
        cmd = { npm.executable(root_dir, "intelephense"), "--stdio" },
    },
}
