local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/latex-lsp/texlab",
        languages = { "latex" },
        installer = function()
            local repo = "latex-lsp/texlab"
            platform.when {
                unix = function()
                    github.untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.is_mac, "texlab-x86_64-macos.tar.gz"),
                            when(platform.is_linux and platform.arch == "x64", "texlab-x86_64-linux.tar.gz")
                        ),
                    }).with_receipt()
                end,
                win = function()
                    github.unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(when(platform.arch == "x64", "texlab-x86_64-windows.zip")),
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
