local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "rome"

return server.Server:new {
    name = "rome",
    root_dir = root_dir,
    installer = npm.packages { "rome@10.0.7-nightly.2021.7.2" }, -- https://github.com/rome/tools/pull/1409
    default_options = {
        cmd = { npm.executable(root_dir, "rome"), "lsp" },
    },
}
