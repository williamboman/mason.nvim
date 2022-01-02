local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local platform = require "nvim-lsp-installer.platform"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/elixir-lsp/elixir-ls",
        languages = { "elixir" },
        installer = {
            context.use_github_release_file("elixir-lsp/elixir-ls", "elixir-ls.zip"),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file, "elixir-ls")
            end),
            std.chmod("+x", { "elixir-ls/language_server.sh" }),
        },
        default_options = {
            cmd = {
                path.concat {
                    root_dir,
                    "elixir-ls",
                    platform.is_win and "language_server.bat" or "language_server.sh",
                },
            },
        },
    }
end
