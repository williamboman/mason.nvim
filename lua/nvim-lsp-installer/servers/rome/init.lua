local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"
local Optional = require "nvim-lsp-installer.core.optional"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "typescript", "javascript" },
        homepage = "https://rome.tools",
        ---@param ctx InstallContext
        installer = function(ctx)
            ctx.requested_version = ctx.requested_version:or_(function()
                return Optional.of "10.0.7-nightly.2021.7.27"
            end)
            npm.install({ "rome" }).with_receipt()
        end,
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
