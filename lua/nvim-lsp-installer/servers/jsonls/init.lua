local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("json")

return server.Server:new {
    name = "jsonls",
    root_dir = root_dir,
    installer = npm.packages { "vscode-json-languageserver" },
    default_options = {
        cmd = { npm.executable(root_dir, "vscode-json-languageserver"), "--stdio" },
    },
}
