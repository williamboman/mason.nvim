local server = require("nvim-lsp-installer.server")
local path = require("nvim-lsp-installer.path")
local shell = require("nvim-lsp-installer.installers.shell")

local root_dir = server.get_server_root_path("denols")

local install_cmd = [=[
export DENO_INSTALL="$PWD"
curl -fsSL https://deno.land/x/install/install.sh | sh
]=]

return server.Server:new {
    name = "denols",
    root_dir = root_dir,
    installer = shell.raw(install_cmd),
    default_options = {
        cmd = { path.concat { root_dir, "bin", "deno" }, "lsp" },
    },
}
