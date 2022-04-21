local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local process = require "nvim-lsp-installer.process"
local Data = require "nvim-lsp-installer.data"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://haskell-language-server.readthedocs.io/en/latest/",
        languages = { "haskell" },
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            github.untargz_release_file({
                repo = "haskell/haskell-language-server",
                asset_file = function(version)
                    local target = coalesce(
                        when(platform.is_mac, "haskell-language-server-macOS-%s.tar.gz"),
                        when(platform.is_linux, "haskell-language-server-Linux-%s.tar.gz"),
                        when(platform.is_win, "haskell-language-server-Windows-%s.tar.gz")
                    )
                    return target and target:format(version)
                end,
            }).with_receipt()
            if platform.is_unix then
                ctx.spawn.sh { "-c", [[ chmod +x haskell* ]] }
            end
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { root_dir },
            },
        },
    }
end
