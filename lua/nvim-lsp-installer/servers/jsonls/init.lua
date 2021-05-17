local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("json")

return server.Server:new {
    name = "jsonls",
    root_dir = root_dir,
    install_cmd = npm.packages { "vscode-json-languageserver" },
    default_options = {
        cmd = { path.concat { root_dir, "node_modules", ".bin", "vscode-json-languageserver" }, "--stdio" },
    },
}
