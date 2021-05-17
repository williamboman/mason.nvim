local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("tsserver")

return server.Server:new {
    name = "tsserver",
    root_dir = root_dir,
    install_cmd = npm.packages { "typescript-language-server" },
    default_options = {
        cmd = { path.concat { root_dir, "node_modules", ".bin", "typescript-language-server" }, "--stdio" },
    },
}
