local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local git = require "nvim-lsp-installer.core.managers.git"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "openapi", "asyncapi" },
        homepage = "https://stoplight.io/open-source/spectral/",
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            git.clone({ "https://github.com/stoplightio/vscode-spectral" }).with_receipt()
            ctx.spawn.npm { "install" }
            ctx:chdir("server", function()
                ctx.spawn.npm { "install" }
            end)
            pcall(npm.run, { "compile" })

            ctx:chdir "server"
            ctx.receipt:mark_invalid() -- Due to the `chdir`, we essentially erase any trace of the cloned git repo, so we mark this as invalid.
        end,
        default_options = {
            cmd = { "node", path.concat { root_dir, "out", "server.js" }, "--stdio" },
        },
    }
end
