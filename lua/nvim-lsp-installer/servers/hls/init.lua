local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local shell = require "nvim-lsp-installer.installers.shell"
local Data = require "nvim-lsp-installer.data"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://haskell-language-server.readthedocs.io/en/latest/",
        languages = { "haskell" },
        installer = {
            context.use_github_release_file("haskell/haskell-language-server", function(version)
                return Data.coalesce(
                    Data.when(platform.is_mac, "haskell-language-server-macOS-%s.tar.gz"),
                    Data.when(platform.is_linux, "haskell-language-server-Linux-%s.tar.gz"),
                    Data.when(platform.is_win, "haskell-language-server-Windows-%s.tar.gz")
                ):format(version)
            end),
            context.capture(function(ctx)
                return std.untargz_remote(ctx.github_release_file)
            end),
            installers.on {
                -- we can't use std.chmod because of shell wildcard expansion
                unix = shell.sh [[ chmod +x haskell* ]],
            },
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
