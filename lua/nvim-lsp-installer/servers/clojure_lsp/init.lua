local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://clojure-lsp.io",
        languages = { "clojure" },
        installer = {
            context.use_github_release_file(
                "clojure-lsp/clojure-lsp",
                Data.coalesce(
                    Data.when(platform.is_mac, "clojure-lsp-native-macos-amd64.zip"),
                    Data.when(platform.is_linux, "clojure-lsp-native-linux-amd64.zip"),
                    Data.when(platform.is_win, "clojure-lsp-native-windows-amd64.zip")
                )
            ),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            std.chmod("+x", { "clojure-lsp" }),
        },
        default_options = {
            cmd = { path.concat { root_dir, "clojure-lsp" } },
        },
    }
end
