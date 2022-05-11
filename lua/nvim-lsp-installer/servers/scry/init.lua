local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local path = require "nvim-lsp-installer.core.path"
local std = require "nvim-lsp-installer.core.managers.std"
local git = require "nvim-lsp-installer.core.managers.git"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "crystal" },
        homepage = "https://github.com/crystal-lang-tools/scry",
        ---@param ctx InstallContext
        installer = function(ctx)
            std.ensure_executable("crystal", {
                help_url = "https://crystal-lang.org/install/",
            })
            std.ensure_executable("shards", {
                help_url = "https://crystal-lang.org/install/",
            })
            git.clone({ "https://github.com/crystal-lang-tools/scry.git" }).with_receipt()
            ctx.spawn.shards { "build", "--verbose", "--release" }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
