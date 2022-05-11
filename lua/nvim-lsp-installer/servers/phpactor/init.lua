local path = require "nvim-lsp-installer.core.path"
local server = require "nvim-lsp-installer.server"
local composer = require "nvim-lsp-installer.core.managers.composer"
local git = require "nvim-lsp-installer.core.managers.git"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://phpactor.readthedocs.io/en/master/",
        languages = { "php" },
        installer = function()
            assert(platform.is_unix, "Phpactor only supports UNIX environments.")
            git.clone({ "https://github.com/phpactor/phpactor.git" }).with_receipt()
            composer.install()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
