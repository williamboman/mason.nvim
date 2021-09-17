local server = require "nvim-lsp-installer.server"
local pip3 = require "nvim-lsp-installer.installers.pip3"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = pip3.packages { "cmake-language-server" },
        default_options = {
            cmd = { pip3.executable(root_dir, "cmake-language-server") },
        },
    }
end
