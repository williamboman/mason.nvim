local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = npm.packages { "rome@10.0.7-nightly.2021.7.2" }, -- https://github.com/rome/tools/pull/1409
        default_options = {
            cmd = { npm.executable(root_dir, "rome"), "lsp" },
        },
    }
end
