local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"
local Data = require "nvim-lsp-installer.data"
local std = require "nvim-lsp-installer.installers.std"
local platform = require "nvim-lsp-installer.platform"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://clangd.llvm.org",
        languages = { "c", "c++" },
        installer = {
            context.use_github_release_file("clangd/clangd", function(version)
                local target_file = Data.coalesce(
                    Data.when(platform.is_mac, "clangd-mac-%s.zip"),
                    Data.when(platform.is_linux and platform.arch == "x64", "clangd-linux-%s.zip"),
                    Data.when(platform.is_win, "clangd-windows-%s.zip")
                )
                return target_file and target_file:format(version)
            end),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            context.capture(function(ctx)
                return std.rename(("clangd_%s"):format(ctx.requested_server_version), "clangd")
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "clangd", "bin" } },
            },
        },
    }
end
