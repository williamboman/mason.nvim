local server = require "nvim-lsp-installer.server"
local pip3 = require "nvim-lsp-installer.installers.pip3"

local root_dir = server.get_server_root_path "cmake"

return server.Server:new {
    name = "cmake",
    root_dir = root_dir,
    installer = pip3.packages { "cmake-language-server" },
    default_options = {
        cmd = { pip3.executable(root_dir, "cmake-language-server") },
    },
}
