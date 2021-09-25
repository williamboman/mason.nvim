local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local std = require "nvim-lsp-installer.installers.std"
local shell = require "nvim-lsp-installer.installers.shell"
local Data = require "nvim-lsp-installer.data"

local VERSION = "1.4.0"

local target = Data.coalesce(
    Data.when(platform.is_mac, "haskell-language-server-macOS-%s.tar.gz"),
    Data.when(platform.is_linux, "haskell-language-server-Linux-%s.tar.gz"),
    Data.when(platform.is_win, "haskell-language-server-Windows-%s.tar.gz")
):format(VERSION)

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            std.untargz_remote(
                ("https://github.com/haskell/haskell-language-server/releases/download/%s/%s"):format(VERSION, target)
            ),
            installers.on {
                -- we can't use std.chmod because of shell wildcard expansion
                unix = shell.bash [[ chmod +x haskell*]],
            },
        },
        default_options = {
            cmd = { path.concat { root_dir, "haskell-language-server-wrapper" }, "--lsp" },
            cmd_env = {
                PATH = table.concat({ root_dir, vim.env.PATH }, platform.path_sep),
            },
        },
    }
end
