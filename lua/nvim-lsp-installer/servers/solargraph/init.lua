local server = require "nvim-lsp-installer.server"
local gem = require "nvim-lsp-installer.installers.gem"

local root_dir = server.get_server_root_path "solargraph"

return server.Server:new {
    name = "solargraph",
    root_dir = root_dir,
    installer = gem.packages { "solargraph" },
    default_options = {
        cmd = { gem.executable(root_dir, "solargraph"), "stdio" },
        cmd_env = gem.env(root_dir),
    },
}
