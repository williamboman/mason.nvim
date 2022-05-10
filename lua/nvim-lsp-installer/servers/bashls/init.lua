local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "bash" },
        homepage = "https://github.com/bash-lsp/bash-language-server",
        installer = npm.packages { "bash-language-server" },
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
