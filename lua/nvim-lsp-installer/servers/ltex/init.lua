local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://valentjn.github.io/vscode-ltex",
        languages = { "latex" },
        installer = {
            context.use_github_release_file("valentjn/ltex-ls", function(version)
                return coalesce(
                    when(platform.is_mac, "ltex-ls-%s-mac-x64.tar.gz"),
                    when(platform.is_linux, "ltex-ls-%s-linux-x64.tar.gz"),
                    when(platform.is_win, "ltex-ls-%s-windows-x64.zip")
                ):format(version)
            end),
            context.capture(function(ctx)
                if platform.is_win then
                    return std.unzip_remote(ctx.github_release_file)
                else
                    return std.untargz_remote(ctx.github_release_file)
                end
            end),
            context.capture(function(ctx)
                return std.rename(("ltex-ls-%s"):format(ctx.requested_server_version), "ltex-ls")
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "ltex-ls", "bin" } },
            },
        },
    }
end
