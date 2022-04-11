local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"
local git = require "nvim-lsp-installer.core.managers.git"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "metamath-zero" },
        homepage = "https://github.com/digama0/mm0",
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            git.clone({ "https://github.com/digama0/mm0" }).with_receipt()
            ctx.spawn.cargo { "build", "--release", cwd = path.concat { ctx.cwd:get(), "mm0-rs" } }
            ctx.receipt:with_primary_source(ctx.receipt.git_remote "https://github.com/digama0/mm0")
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "mm0-rs", "target", "release" } },
            },
        },
    }
end
