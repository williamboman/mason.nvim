local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/aca/emmet-ls",
        languages = { "emmet" },
        installer = npm.packages { "emmet-ls" },
        default_options = {
            cmd = { npm.executable(root_dir, "emmet-ls"), "--stdio" },
        },
    }
end
