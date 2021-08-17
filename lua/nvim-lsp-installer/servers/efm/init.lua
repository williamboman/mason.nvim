local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.installers.go"

local root_dir = server.get_server_root_path "efm"

return server.Server:new {
    name = "efm",
    root_dir = root_dir,
    installer = go.packages { "github.com/mattn/efm-langserver" },
    default_options = {
        cmd = { go.executable(root_dir, "efm-langserver") },
    },
}
