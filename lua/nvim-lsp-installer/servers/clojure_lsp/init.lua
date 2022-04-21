local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://clojure-lsp.io",
        languages = { "clojure" },
        async = true,
        installer = function()
            github.unzip_release_file({
                repo = "clojure-lsp/clojure-lsp",
                asset_file = coalesce(
                    when(platform.is_mac, "clojure-lsp-native-macos-amd64.zip"),
                    when(platform.is_linux, "clojure-lsp-native-linux-amd64.zip"),
                    when(platform.is_win, "clojure-lsp-native-windows-amd64.zip")
                ),
            }).with_receipt()
            std.chmod("+x", { "clojure-lsp" })
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
