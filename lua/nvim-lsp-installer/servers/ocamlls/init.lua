local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "ocamlls"

return server.Server:new {
    name = "ocamlls",
    root_dir = root_dir,
    installer = npm.packages { "ocaml-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "ocaml-language-server"), "--stdio" },
    },
}
