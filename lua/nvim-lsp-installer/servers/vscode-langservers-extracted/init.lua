local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

local root_dir = server.get_server_root_path "vscode-langservers-extracted"

return function(name, executable)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = npm.packages { "vscode-langservers-extracted" },
        default_options = {
            cmd = { npm.executable(root_dir, executable), "--stdio" },
        },
    }
end
