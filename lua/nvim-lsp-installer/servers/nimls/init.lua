local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local git = require "nvim-lsp-installer.core.managers.git"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/PMunch/nimlsp",
        languages = { "nim" },
        ---@param ctx InstallContext
        installer = function(ctx)
            git.clone({ "https://github.com/PMunch/nimlsp.git" }).with_receipt()
            ctx.spawn.nimble { "build", "-y", "--localdeps" }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
