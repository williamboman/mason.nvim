local util = require("lspconfig.util")

local server = require("nvim-lsp-installer.server")

local root_dir = server.get_server_root_path("vuels")

return server.Server:new {
    name = "vuels",
    root_dir = root_dir,
    install_cmd = [[npm install vls]],
    default_options = {
        cmd = { root_dir .. "/node_modules/.bin/vls", "--stdio"},
    },
}
