local server = require "nvim-lsp-installer.server"
local cargo = require "nvim-lsp-installer.core.managers.cargo"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "flux" },
        homepage = "https://github.com/influxdata/flux-lsp",
        installer = cargo.crate("https://github.com/influxdata/flux-lsp", {
            git = true,
        }),
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
