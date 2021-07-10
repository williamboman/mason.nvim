local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("css")

return server.Server:new {
    name = "cssls",
    root_dir = root_dir,
    installer = npm.packages { "vscode-css-languageserver-bin" },
    default_options = {
        cmd = { npm.executable(root_dir, "css-languageserver") , "--stdio" },
    },
}
