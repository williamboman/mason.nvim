local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.core.managers.go"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://pkg.go.dev/golang.org/x/tools/gopls",
        languages = { "go" },
        installer = go.packages { "golang.org/x/tools/gopls" },
        default_options = {
            cmd_env = go.env(root_dir),
        },
    }
end
