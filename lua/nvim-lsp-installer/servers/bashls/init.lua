local server = require("nvim-lsp-installer.server")
local npm = require("nvim-lsp-installer.installers.npm")

local root_dir = server.get_server_root_path("bash")

return server.Server:new {
    name = "bashls",
    root_dir = root_dir,
    installer = npm.packages { "bash-language-server@latest" },
    default_options = {
        cmd = { npm.executable(root_dir, "bash-language-server"), "start" },
    },
}
