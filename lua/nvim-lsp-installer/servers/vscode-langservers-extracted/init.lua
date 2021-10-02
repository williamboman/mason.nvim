local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(executable)
    return function(name, root_dir)
        return server.Server:new {
            name = name,
            root_dir = root_dir,
            installer = npm.packages { "vscode-langservers-extracted" },
            default_options = {
                cmd = { npm.executable(root_dir, executable), "--stdio" },
            },
        }
    end
end
