local server = require "nvim-lsp-installer.server"
local cargo = require "nvim-lsp-installer.installers.cargo"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "toml" },
        homepage = "https://taplo.tamasfe.dev/lsp/",
        installer = cargo.crates { "taplo-lsp" },
        default_options = {
            cmd = { cargo.executable(root_dir, "taplo-lsp"), "run" },
        },
    }
end
