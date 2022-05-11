local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.core.platform"
local functional = require "nvim-lsp-installer.core.functional"
local process = require "nvim-lsp-installer.core.process"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/Pure-D/serve-d",
        languages = { "d" },
        installer = function()
            local repo = "Pure-D/serve-d"
            platform.when {
                unix = function()
                    github.untarxz_release_file({
                        repo = repo,
                        asset_file = function(release)
                            local target = coalesce(
                                when(platform.is_mac, "serve-d_%s-osx-x86_64.tar.xz"),
                                when(platform.is_linux and platform.arch == "x64", "serve-d_%s-linux-x86_64.tar.xz")
                            )
                            return target and target:format(release:gsub("^v", ""))
                        end,
                    }).with_receipt()
                end,
                win = function()
                    github.unzip_release_file({
                        repo = repo,
                        asset_file = function(release)
                            local target = coalesce(when(platform.arch == "x64"), "serve-d_%s-windows-x86_64.zip")
                            return target and target:format(release:gsub("^v", ""))
                        end,
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
