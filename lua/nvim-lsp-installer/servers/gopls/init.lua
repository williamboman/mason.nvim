local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.installers.go"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = go.packages { "golang.org/x/tools/gopls@latest" },
        default_options = {
            cmd = { go.executable(root_dir, "gopls") },
        },
    }
end
