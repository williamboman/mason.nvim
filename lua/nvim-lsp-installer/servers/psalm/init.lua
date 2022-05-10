local server = require "nvim-lsp-installer.server"
local composer = require "nvim-lsp-installer.core.managers.composer"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://psalm.dev/",
        languages = { "php" },
        installer = composer.packages { "vimeo/psalm" },
        default_options = {
            cmd_env = composer.env(root_dir),
        },
    }
end
