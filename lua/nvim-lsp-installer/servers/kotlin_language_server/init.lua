local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/fwcd/kotlin-language-server",
        languages = { "kotlin" },
        installer = {
            context.use_github_release_file("fwcd/kotlin-language-server", "server.zip"),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path {
                    path.concat {
                        root_dir,
                        "server",
                        "bin",
                    },
                },
            },
        },
    }
end
