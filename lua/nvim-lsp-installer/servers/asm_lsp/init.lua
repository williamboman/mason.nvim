local server = require "nvim-lsp-installer.server"
local cargo = require "nvim-lsp-installer.core.managers.cargo"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "assembly-gas", "assembly-nasm", "assembly-go" },
        homepage = "https://github.com/bergercookie/asm-lsp",
        installer = cargo.crate "asm-lsp",
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
