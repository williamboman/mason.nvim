local server = require "nvim-lsp-installer.server"
local gem = require "nvim-lsp-installer.core.managers.gem"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://sorbet.org/",
        languages = { "ruby" },
        installer = gem.packages { "sorbet" },
        default_options = {
            cmd_env = gem.env(root_dir),
        },
    }
end
