local server = require "nvim-lsp-installer.server"
local go = require "nvim-lsp-installer.installers.go"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "sql" },
        homepage = "https://github.com/lighttiger2505/sqls",
        installer = go.packages { "github.com/lighttiger2505/sqls" },
        default_options = {
            cmd = { go.executable(root_dir, "sqls") },
        },
    }
end
