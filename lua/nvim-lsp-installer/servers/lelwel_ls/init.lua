local server = require "nvim-lsp-installer.server"
local cargo = require "nvim-lsp-installer.core.managers.cargo"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "lelwel" },
        homepage = "https://github.com/0x2a-42/lelwel",
        installer = cargo.crate("lelwel", {
            features = "lsp",
        }),
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
