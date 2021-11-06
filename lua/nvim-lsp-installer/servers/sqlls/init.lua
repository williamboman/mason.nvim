local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "sql" },
        homepage = "https://github.com/joe-re/sql-language-server",
        installer = npm.packages { "sql-language-server" },
        default_options = {
            cmd = { npm.executable(root_dir, "sql-language-server"), "up", "--method", "stdio" },
        },
    }
end
