local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"

local root_dir = server.get_server_root_path "rescriptls"

return server.Server:new {
    name = "rescriptls",
    root_dir = root_dir,
    installer = installers.when {
        unix = shell.bash [[
           curl -fs https://api.github.com/repos/rescript-lang/rescript-vscode/releases/latest \
                  | grep "browser_download_url.*vsix" \
                  | cut -d : -f 2,3 \
                  | tr -d '"' \
                  | wget -i - -O vscode-rescript.vsix;
            unzip -q -o vscode-rescript.vsix;
            rm -f vscode-rescript.vsix;
        ]],
    },
    default_options = {
        cmd = { "node", path.concat { root_dir, "extension", "server", "out", "server.js" }, "--stdio" },
    },
}
