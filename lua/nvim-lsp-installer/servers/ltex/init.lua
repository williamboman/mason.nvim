local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://valentjn.github.io/vscode-ltex",
        languages = { "latex" },
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            if platform.is_win then
                local release_source = github.unzip_release_file {
                    repo = "valentjn/ltex-ls",
                    asset_file = function(version)
                        return ("ltex-ls-%s-windows-x64.zip"):format(version)
                    end,
                }
                release_source.with_receipt()
                ctx.fs:rename(("ltex-ls-%s"):format(release_source.release), "ltex-ls")
            else
                local release_source = github.untargz_release_file {
                    repo = "valentjn/ltex-ls",
                    asset_file = function(version)
                        local target = coalesce(
                            when(platform.is_mac, "ltex-ls-%s-mac-x64.tar.gz"),
                            when(platform.is_linux, "ltex-ls-%s-linux-x64.tar.gz"),
                            when(platform.is_win, "ltex-ls-%s-windows-x64.zip")
                        )
                        return target:format(version)
                    end,
                }
                release_source.with_receipt()
                ctx.fs:rename(("ltex-ls-%s"):format(release_source.release), "ltex-ls")
            end
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "ltex-ls", "bin" } },
            },
        },
    }
end
