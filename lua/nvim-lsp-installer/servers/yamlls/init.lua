local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("yaml")

return server.Server:new {
    name = "yamlls",
    root_dir = root_dir,
    install_cmd = npm.packages { "yaml-language-server" },
    default_options = {
        cmd = { path.concat { root_dir, "node_modules", ".bin", "yaml-language-server" }, "--stdio" },
    }
}
