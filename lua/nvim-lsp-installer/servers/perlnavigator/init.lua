local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "perl" },
        homepage = "https://github.com/bscan/PerlNavigator",
        installer = npm.packages { "perlnavigator-server" },
        async = true,
        default_options = {
            cmd = {
                "node",
                path.concat { root_dir, "node_modules", "perlnavigator-server", "out", "server.js" },
                "--stdio",
            },
        },
    }
end
