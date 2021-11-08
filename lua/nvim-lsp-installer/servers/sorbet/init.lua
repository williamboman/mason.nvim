local server = require "nvim-lsp-installer.server"
local gem = require "nvim-lsp-installer.installers.gem"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "ruby" },
        installer = gem.packages { "sorbet" },
        default_options = {
            cmd = { gem.executable(root_dir, "srb"), "tc", "--lsp" },
            cmd_env = gem.env(root_dir),
        },
    }
end
