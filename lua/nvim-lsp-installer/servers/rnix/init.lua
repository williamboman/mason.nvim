local server = require "nvim-lsp-installer.server"
local cargo = require "nvim-lsp-installer.core.managers.cargo"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "nix" },
        homepage = "https://github.com/nix-community/rnix-lsp",
        installer = cargo.crate "rnix-lsp",
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
