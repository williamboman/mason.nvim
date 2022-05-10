local server = require "nvim-lsp-installer.server"
local pip3 = require "nvim-lsp-installer.core.managers.pip3"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = pip3.packages { "robotframework-lsp" },
        languages = { "robot" },
        homepage = "https://github.com/robocorp/robotframework-lsp",
        default_options = {
            cmd_env = pip3.env(root_dir),
        },
    }
end
