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
        homepage = "https://github.com/mickael-menu/zk",
        languages = { "markdown" },
        installer = function()
            local repo = "mickael-menu/zk"
            platform.when {
                mac = function()
                    github.unzip_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("zk-%s-macos-arm64.zip"):format(version)
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("zk-%s-macos-x86_64.zip"):format(version)
                            end)
                        ),
                    }):with_receipt()
                end,
                linux = function()
                    github.untargz_release_file({
                        repo = repo,
                        asset_file = coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("zk-%s-linux-arm64.tar.gz"):format(version)
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("zk-%s-linux-amd64.tar.gz"):format(version)
                            end),
                            when(platform.arch == "x86", function(version)
                                return ("zk-%s-linux-i386.tar.gz"):format(version)
                            end)
                        ),
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
