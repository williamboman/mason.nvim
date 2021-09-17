local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"

local VERSION = "12.0.1"

local target = Data.coalesce(
    Data.when(platform.is_mac, "clangd-mac-%s.zip"),
    Data.when(platform.is_linux, "clangd-linux-%s.zip"),
    Data.when(platform.is_win, "clangd-windows-%s.zip")
):format(VERSION)

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = std.unzip_remote(
            ("https://github.com/clangd/clangd/releases/download/%s/%s"):format(VERSION, target)
        ),
        default_options = {
            cmd = { path.concat { root_dir, ("clangd_%s"):format(VERSION), "bin", "clangd" } },
        },
    }
end
