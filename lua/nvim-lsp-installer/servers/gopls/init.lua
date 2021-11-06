local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.installers.go"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://pkg.go.dev/golang.org/x/tools/gopls",
        languages = { "go" },
        installer = go.packages { "golang.org/x/tools/gopls" },
        default_options = {
            cmd = { go.executable(root_dir, "gopls") },
        },
    }
end
