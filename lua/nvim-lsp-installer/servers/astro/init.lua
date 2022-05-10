local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "astro" },
        homepage = "https://github.com/withastro/language-tools/tree/main/packages/language-server",
        installer = npm.packages { "@astrojs/language-server" },
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
