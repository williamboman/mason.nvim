local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("purescript")

return server.Server:new {
    name = "purescriptls",
    root_dir = root_dir,
    installer = npm.packages { "purescript-language-server" },
    default_options = {
        cmd = { path.concat { root_dir, "node_modules", ".bin", "purescript-language-server" }, "--stdio" },
    },
}
