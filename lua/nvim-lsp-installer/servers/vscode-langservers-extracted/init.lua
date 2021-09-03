local server = require "nvim-lsp-installer.server"
local opts = require "nvim-lsp-installer.opts"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "vscode-langservers-extracted"

return function(name, executable)
    local resolved_root_dir = opts.allow_federated_servers() and root_dir or ("%s_%s"):format(root_dir, name)

    return server.Server:new {
        name = name,
        root_dir = resolved_root_dir,
        installer = npm.packages { "vscode-langservers-extracted" },
        default_options = {
            cmd = { npm.executable(resolved_root_dir, executable), "--stdio" },
        },
    }
end
