local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when
return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/mickael-menu/zk",
        languages = { "markdown" },
        installer = {
            context.use_github_release_file(
                "mickael-menu/zk",
                coalesce(
                    when(
                        platform.is_mac,
                        coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("zk-%s-macos-arm64.zip"):format(version)
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("zk-%s-macos-x86_64.zip"):format(version)
                            end)
                        )
                    ),
                    when(
                        platform.is_linux,
                        coalesce(
                            when(platform.arch == "arm64", function(version)
                                return ("zk-%s-linux-arm64.tar.gz"):format(version)
                            end),
                            when(platform.arch == "x64", function(version)
                                return ("zk-%s-linux-amd64.tar.gz"):format(version)
                            end),
                            when(platform.arch == "x86", function(version)
                                return ("zk-%s-linux-i386.tar.gz"):format(version)
                            end)
                        )
                    )
                )
            ),
            context.capture(coalesce(
                when(platform.is_mac, function(ctx)
                    return std.unzip_remote(ctx.github_release_file)
                end),
                when(platform.is_linux, function(ctx)
                    return std.untargz_remote(ctx.github_release_file)
                end)
            )),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
