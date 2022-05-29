local server = require "nvim-lsp-installer.server"
local luarocks = require "nvim-lsp-installer.core.managers.luarocks"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "teal" },
        homepage = "https://github.com/teal-language/teal-language-server",
        installer = luarocks.package("teal-language-server", { dev = true }),
        default_options = {
            cmd_env = luarocks.env(root_dir),
        },
    }
end
