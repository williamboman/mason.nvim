local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local process = require "nvim-lsp-installer.core.process"
local functional = require "nvim-lsp-installer.core.functional"
local platform = require "nvim-lsp-installer.core.platform"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = functional.coalesce, functional.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://clangd.llvm.org",
        languages = { "c", "c++" },
        ---@param ctx InstallContext
        installer = function(ctx)
            local source = github.unzip_release_file {
                repo = "clangd/clangd",
                asset_file = function(release)
                    local target = coalesce(
                        when(platform.is_mac, "clangd-mac-%s.zip"),
                        when(platform.is_linux and platform.arch == "x64", "clangd-linux-%s.zip"),
                        when(platform.is_win, "clangd-windows-%s.zip")
                    )
                    return target and target:format(release)
                end,
            }
            source.with_receipt()
            ctx.fs:rename(("clangd_%s"):format(source.release), "clangd")
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "clangd", "bin" } },
            },
        },
    }
end
