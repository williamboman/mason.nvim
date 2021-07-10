local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("html")

return server.Server:new {
    name = "html",
    root_dir = root_dir,
    installer = npm.packages { "vscode-html-languageserver-bin" },
    default_options = {
        cmd = { npm.executable(root_dir, "html-languageserver"), "--stdio" },
    },
}
