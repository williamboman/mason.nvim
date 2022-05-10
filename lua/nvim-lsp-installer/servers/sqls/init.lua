local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.core.managers.go"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "sql" },
        homepage = "https://github.com/lighttiger2505/sqls",
        installer = go.packages { "github.com/lighttiger2505/sqls" },
        default_options = {
            cmd_env = go.env(root_dir),
        },
    }
end
