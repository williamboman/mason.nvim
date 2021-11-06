local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = {},
        homepage = "https://github.com/iamcco/diagnostic-languageserver",
        installer = npm.packages { "diagnostic-languageserver" },
        default_options = {
            cmd = { npm.executable(root_dir, "diagnostic-languageserver"), "--stdio" },
        },
    }
end
