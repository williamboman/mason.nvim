local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.core.managers.go"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/mattn/efm-langserver",
        languages = {},
        installer = go.packages { "github.com/mattn/efm-langserver" },
        default_options = {
            cmd_env = go.env(root_dir),
        },
    }
end
