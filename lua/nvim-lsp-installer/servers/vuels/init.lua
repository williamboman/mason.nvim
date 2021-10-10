local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/vlang/vls",
        installer = npm.packages { "vls" },
        default_options = {
            cmd = { npm.executable(root_dir, "vls"), "--stdio" },
        },
    }
end
