local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "svelte"

return server.Server:new {
    name = "svelte",
    root_dir = root_dir,
    installer = npm.packages { "svelte-language-server" },
    default_options = {
        cmd = { npm.executable(root_dir, "svelteserver"), "--stdio" },
    },
}
