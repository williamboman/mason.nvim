local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"
local Data = require "nvim-lsp-installer.data"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "typescript", "javascript" },
        homepage = "https://rome.tools",
        installer = {
            context.set(function(ctx)
                ctx.requested_server_version = Data.coalesce(
                    ctx.requested_server_version,
                    "10.0.7-nightly.2021.7.27" -- https://github.com/rome/tools/pull/1409
                )
            end),
            npm.packages { "rome" },
        },
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
