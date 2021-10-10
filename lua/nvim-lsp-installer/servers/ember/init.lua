local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/lifeart/ember-language-server",
        installer = npm.packages { "@lifeart/ember-language-server" },
        default_options = {
            cmd = { npm.executable(root_dir, "ember-language-server"), "--stdio" },
        },
    }
end
