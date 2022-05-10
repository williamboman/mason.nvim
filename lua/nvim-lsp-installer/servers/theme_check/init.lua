local server = require "nvim-lsp-installer.server"
local gem = require "nvim-lsp-installer.core.managers.gem"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "liquid" },
        homepage = "https://github.com/Shopify/theme-check",
        installer = gem.packages { "theme-check" },
        default_options = {
            cmd_env = gem.env(root_dir),
        },
    }
end
