local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "python" },
        homepage = "https://github.com/microsoft/pyright",
        installer = npm.packages { "pyright" },
        default_options = {
            cmd = { npm.executable(root_dir, "pyright-langserver"), "--stdio" },
        },
    }
end
