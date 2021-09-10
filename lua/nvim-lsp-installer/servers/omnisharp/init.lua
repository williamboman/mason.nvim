local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"

local root_dir = server.get_server_root_path "omnisharp"

local VERSION = "v1.37.15"

local target = Data.coalesce(
    Data.when(platform.is_mac, "omnisharp-osx.zip"),
    Data.when(platform.is_unix and platform.arch == "x64", "omnisharp-linux-x64.zip"),
    Data.when(
        platform.is_win,
        Data.coalesce(
            Data.when(platform.arch == "x64", "omnisharp-win-x64.zip"),
            Data.when(platform.arch == "arm64", "omnisharp-win-arm64.zip")
        )
    )
)

return server.Server:new {
    name = "omnisharp",
    root_dir = root_dir,
    installer = {
        std.unzip_remote(
            ("https://github.com/OmniSharp/omnisharp-roslyn/releases/download/%s/%s"):format(VERSION, target),
            "omnisharp"
        ),
        std.chmod("+x", { "omnisharp/run" }),
    },
    default_options = {
        cmd = {
            platform.is_win and path.concat { root_dir, "OmniSharp.exe" }
                or path.concat { root_dir, "omnisharp", "run" },
            "--languageserver",
            "--hostPID",
            tostring(vim.fn.getpid()),
        },
    },
}
