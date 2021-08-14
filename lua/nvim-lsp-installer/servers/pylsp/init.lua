local server = require "nvim-lsp-installer.server"
local pip3 = require "nvim-lsp-installer.installers.pip3"

local root_dir = server.get_server_root_path "pylsp"

return server.Server:new {
    name = "pylsp",
    root_dir = root_dir,
    installer = pip3.packages { "python-lsp-server[all]" },
    default_options = {
        cmd = { pip3.executable(root_dir, "pylsp") },
    },
}
