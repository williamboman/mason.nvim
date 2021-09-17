local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"

local VERSION = "2021.07.01-19.49.02"

local target = Data.coalesce(
    Data.when(platform.is_mac, "clojure-lsp-native-macos-amd64.zip"),
    Data.when(platform.is_linux, "clojure-lsp-native-linux-amd64.zip"),
    Data.when(platform.is_win, "clojure-lsp-native-windows-amd64.zip")
)

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            std.unzip_remote(
                ("https://github.com/clojure-lsp/clojure-lsp/releases/download/%s/%s"):format(VERSION, target)
            ),
            std.chmod("+x", { "clojure-lsp" }),
        },
        default_options = {
            cmd = { path.concat { root_dir, "clojure-lsp" } },
        },
    }
end
