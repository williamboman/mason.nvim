local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("python")

return server.Server:new {
    name = "pyright",
    root_dir = root_dir,
    installer = npm.packages { "pyright" },
    default_options = {
        cmd = { npm.executable(root_dir, "pyright-langserver"), "--stdio" },
    },
}
