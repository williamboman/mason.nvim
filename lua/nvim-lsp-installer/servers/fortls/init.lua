local server = require "nvim-lsp-installer.server"
local pip3 = require "nvim-lsp-installer.core.managers.pip3"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/gnikit/fortls",
        languages = { "fortran" },
        installer = pip3.packages { "fortls" },
        default_options = {
            cmd_env = pip3.env(root_dir),
        },
    }
end
