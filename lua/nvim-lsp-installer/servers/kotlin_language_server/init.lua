local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
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
            cmd = {
                path.concat {
                    root_dir,
                    "server",
                    "bin",
                    platform.is_win and "kotlin-language-server.bat" or "kotlin-language-server",
                },
            },
        },
    }
end
