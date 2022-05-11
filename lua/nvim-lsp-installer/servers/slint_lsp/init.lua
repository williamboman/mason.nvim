local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local process = require "nvim-lsp-installer.core.process"
local github = require "nvim-lsp-installer.core.managers.github"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://slint-ui.com/",
        languages = { "slint" },
        installer = function()
            local repo = "slint-ui/slint"
            platform.when {
                win = function()
                    github.unzip_release_file({
                        repo = repo,
                        asset_file = "slint-lsp-windows.zip",
                    }).with_receipt()
                end,
                linux = function()
                    github.untargz_release_file({
                        repo = repo,
                        asset_file = "slint-lsp-linux.tar.gz",
                    }).with_receipt()
                end,
            }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "slint-lsp" } },
            },
        },
    }
end
