local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local process = require "nvim-lsp-installer.core.process"
local git = require "nvim-lsp-installer.core.managers.git"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "metamath-zero" },
        homepage = "https://github.com/digama0/mm0",
        ---@param ctx InstallContext
        installer = function(ctx)
            git.clone({ "https://github.com/digama0/mm0" }).with_receipt()
            ctx:chdir("mm0-rs", function()
                ctx.spawn.cargo { "build", "--release" }
            end)
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "mm0-rs", "target", "release" } },
            },
        },
    }
end
