local path = require "nvim-lsp-installer.path"
local server = require "nvim-lsp-installer.server"
local composer = require "nvim-lsp-installer.core.managers.composer"
local git = require "nvim-lsp-installer.core.managers.git"
local installer = require "nvim-lsp-installer.core.installer"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://phpactor.readthedocs.io/en/master/",
        languages = { "php" },
        async = true,
        installer = installer.serial {
            function()
                assert(platform.is_unix, "Phpactor only supports UNIX environments.")
            end,
            git.clone { "https://github.com/phpactor/phpactor.git" },
            composer.install(),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
