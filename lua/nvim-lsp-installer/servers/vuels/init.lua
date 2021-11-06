local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "vue" },
        homepage = "https://github.com/vuejs/vetur",
        installer = npm.packages { "vls" },
        default_options = {
            cmd = { npm.executable(root_dir, "vls"), "--stdio" },
        },
    }
end
