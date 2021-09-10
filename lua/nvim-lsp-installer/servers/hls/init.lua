local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local installers = require "nvim-lsp-installer.installers"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local shell = require "nvim-lsp-installer.installers.shell"
local Data = require "nvim-lsp-installer.data"

local root_dir = server.get_server_root_path "haskell"

local VERSION = "1.3.0"

local target = Data.coalesce(
    Data.when(platform.is_mac, "haskell-language-server-macOS-%s.tar.gz"),
    Data.when(platform.is_unix, "haskell-language-server-Linux-%s.tar.gz"),
    Data.when(platform.is_win, "haskell-language-server-Windows-%s.tar.gz")
):format(VERSION)

return server.Server:new {
    name = "hls",
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
        cmd = { path.concat { root_dir, "haskell-language-server-wrapper", "--lsp" } },
        cmd_env = {
            PATH = table.concat({ root_dir, vim.env.PATH }, platform.path_sep),
        },
    },
}
