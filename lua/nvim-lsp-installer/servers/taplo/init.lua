local server = require "nvim-lsp-installer.server"
local cargo = require "nvim-lsp-installer.core.managers.cargo"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "toml" },
        homepage = "https://taplo.tamasfe.dev/lsp/",
        installer = cargo.crate "taplo-cli",
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
