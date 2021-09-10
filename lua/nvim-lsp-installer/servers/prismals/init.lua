local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "prismals"

return server.Server:new {
    name = "prismals",
    root_dir = root_dir,
    installer = npm.packages { "@prisma/language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "prisma-language-server"), "--stdio" },
    },
}
