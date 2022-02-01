local server = require "nvim-lsp-installer.server"
local gem = require "nvim-lsp-installer.installers.gem"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "ruby" },
        homepage = "https://github.com/ruby/typeprof",
        installer = gem.packages { "typeprof" },
        default_options = {
            cmd_env = gem.env(root_dir),
        },
    }
end
