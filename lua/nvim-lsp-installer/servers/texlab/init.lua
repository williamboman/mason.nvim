local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"

local VERSION = "v3.2.0"

local target = Data.coalesce(
    Data.when(platform.is_mac, "texlab-x86_64-macos.tar.gz"),
    Data.when(platform.is_linux, "texlab-x86_64-linux.tar.gz"),
    Data.when(platform.is_win, "texlab-x86_64-windows.tar.gz")
)

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = {
            std.ensure_executables {
                { "pdflatex", "A TeX distribution is not installed. Refer to https://www.latex-project.org/get/." },
            },
            std.untargz_remote(("https://github.com/latex-lsp/texlab/releases/download/%s/%s"):format(VERSION, target)),
        },
        default_options = {
            cmd = { path.concat { root_dir, "texlab" } },
        },
    }
end
