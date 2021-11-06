local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/nikeee/dot-language-server",
        languages = { "dot" },
        installer = npm.packages { "dot-language-server" },
        default_options = {
            cmd = { npm.executable(root_dir, "dot-language-server"), "--stdio" },
        },
    }
end
