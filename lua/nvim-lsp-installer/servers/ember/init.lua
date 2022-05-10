local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "ember" },
        homepage = "https://github.com/lifeart/ember-language-server",
        installer = npm.packages { "@lifeart/ember-language-server" },
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
