local server = require("nvim-lsp-installer.server")

local root_dir = server.get_server_root_path("denols")

local install_cmd = [=[
export DENO_INSTALL="$PWD"
curl -fsSL https://deno.land/x/install/install.sh | sh
]=]

return server.Server:new {
    name = "denols",
    root_dir = root_dir,
    install_cmd = install_cmd,
    default_options = {
        cmd = { root_dir .. "/bin/deno", "lsp" },
    },
}
