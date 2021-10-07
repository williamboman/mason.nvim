local server = require "nvim-lsp-installer.server"
local composer = require "nvim-lsp-installer.installers.composer"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = composer.packages { "phpactor/phpactor" },
        default_options = {
            cmd = { composer.executable(root_dir, "phpactor"), "language-server" },
        },
    }
end
