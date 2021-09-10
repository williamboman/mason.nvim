local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "tailwindcss_npm"

return server.Server:new {
    name = "tailwindcss",
    root_dir = root_dir,
    installer = npm.packages { "@tailwindcss/language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "tailwindcss-language-server"), "--stdio" },
    },
}
