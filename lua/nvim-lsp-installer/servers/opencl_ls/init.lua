local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/Galarius/opencl-language-server",
        languages = { "opencl" },
        async = true,
        installer = function()
            platform.when {
                unix = function()
                    local asset_file = coalesce(
                        when(platform.is_mac, "opencl-language-server-darwin-x86_64.tar.gz"),
                        when(platform.is_linux and platform.arch == "x64", "opencl-language-server-linux-x86_64.tar.gz")
                    )
                    github.untargz_release_file({
                        repo = "Galarius/opencl-language-server",
                        asset_file = asset_file,
                    }).with_receipt()
                end,
                win = function()
                    github.unzip_release_file({
                        repo = "Galarius/opencl-language-server",
                        asset_file = "opencl-language-server-win32-x86_64.zip",
                    }).with_receipt()
                end,
            }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
