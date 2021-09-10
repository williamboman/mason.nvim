local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "ansiblels"

return server.Server:new {
    name = "ansiblels",
    root_dir = root_dir,
    installer = {
        std.git_clone "https://github.com/ansible/ansible-language-server",
        npm.install(),
        npm.run "compile",
        npm.install(true),
    },
    default_options = {
        filetypes = { "yaml", "yaml.ansible" },
        cmd = { "node", path.concat { root_dir, "out", "server", "src", "server.js" }, "--stdio" },
    },
}
