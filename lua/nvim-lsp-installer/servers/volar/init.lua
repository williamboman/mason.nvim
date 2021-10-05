local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = npm.packages { "@volar/server" },
        default_options = {
            cmd = { npm.executable(root_dir, "volar-server"), "--stdio" },
        },
    }
end
