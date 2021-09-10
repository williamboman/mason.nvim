local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local std = require "nvim-lsp-installer.installers.std"
local Data = require "nvim-lsp-installer.data"

local root_dir = server.get_server_root_path "terraform"

local VERSION = "0.21.0"

local target = Data.coalesce(
    Data.when(
        platform.is_mac,
        Data.coalesce(
            Data.when(platform.arch == "arm64", "terraform-ls_%s_darwin_arm64.zip"),
            Data.when(platform.arch == "x64", "terraform-ls_%s_darwin_amd64.zip")
        )
    ),
    Data.when(
        platform.is_unix,
        Data.coalesce(
            Data.when(platform.arch == "arm64", "terraform-ls_%s_linux_arm64.zip"),
            Data.when(platform.arch == "arm", "terraform-ls_%s_linux_arm.zip"),
            Data.when(platform.arch == "x64", "terraform-ls_%s_linux_amd64.zip")
        )
    ),
    Data.when(platform.is_win, Data.coalesce(Data.when(platform.arch == "x64", "terraform-ls_%s_windows_amd64.zip")))
):format(VERSION)

return server.Server:new {
    name = "terraformls",
    root_dir = root_dir,
    installer = std.unzip_remote(
        ("https://github.com/hashicorp/terraform-ls/releases/download/v%s/%s"):format(VERSION, target),
        "terraform-ls"
    ),
    default_options = {
        cmd = { path.concat { root_dir, "terraform-ls", "terraform-ls" }, "serve" },
    },
}
