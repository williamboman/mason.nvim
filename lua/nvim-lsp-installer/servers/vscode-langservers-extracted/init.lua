local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "vscode-langservers-extracted"

return function(name, executable)
    return server.Server:new {
        name = name,
        root_dir = vim.g.lsp_installer_allow_federated_servers and root_dir or ("%s_%s"):format(root_dir, name),
        installer = npm.packages { "vscode-langservers-extracted" },
        default_options = {
            cmd = { npm.executable(root_dir, executable), "--stdio" },
        },
    }
end
