local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("vuels")

return server.Server:new {
    name = "vuels",
    root_dir = root_dir,
    install_cmd = npm.packages { "vls" },
    default_options = {
        cmd = { path.concat { root_dir, "node_modules", ".bin", "vls" }, "--stdio"},
    },
}
