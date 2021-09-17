local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"

local root_dir = server.get_server_root_path "latex"

local VERSION = "v3.2.0"

local target = Data.coalesce(
    Data.when(platform.is_mac, "texlab-x86_64-macos.tar.gz"),
    Data.when(platform.is_unix, "texlab-x86_64-linux.tar.gz"),
    Data.when(platform.is_win, "texlab-x86_64-windows.tar.gz")
)

return server.Server:new {
    name = "texlab",
    root_dir = root_dir,
    installer = {
        std.ensure_executables {
            { "pdflatex" , "A TeX distribution is not installed. Refer to https://www.latex-project.org/get/." },
        },
        std.untargz_remote(("https://github.com/latex-lsp/texlab/releases/download/%s/%s"):format(VERSION, target)),
    },
    default_options = {
        cmd = { path.concat { root_dir, "texlab" } },
    },
}
