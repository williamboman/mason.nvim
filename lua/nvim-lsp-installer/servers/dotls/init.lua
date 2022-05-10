local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/nikeee/dot-language-server",
        languages = { "dot" },
        installer = npm.packages { "dot-language-server" },
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
