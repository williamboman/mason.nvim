local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"

local root_dir = server.get_server_root_path "denols"

return server.Server:new {
    name = "denols",
    root_dir = root_dir,
    installer = installers.when {
        unix = shell.remote_bash("https://deno.land/x/install/install.sh", {
            env = {
                DENO_INSTALL = root_dir,
            },
        }),
    },
    default_options = {
        cmd = { path.concat { root_dir, "bin", "deno" }, "lsp" },
    },
}
