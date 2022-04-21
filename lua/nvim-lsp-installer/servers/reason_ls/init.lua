local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"
local github = require "nvim-lsp-installer.core.managers.github"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "reason" },
        homepage = "https://github.com/jaredly/reason-language-server",
        async = true,
        ---@param ctx InstallContext
        installer = function(ctx)
            local archive_name = coalesce(
                when(platform.is_mac, "rls-macos"),
                when(platform.is_linux, "rls-linux"),
                when(platform.is_win, "rls-windows")
            )
            github.unzip_release_file({
                repo = "jaredly/reason-language-server",
                asset_file = ("%s.zip"):format(archive_name),
            }).with_receipt()
            ctx.fs:rename(archive_name, "reason")
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "reason" } },
            },
        },
    }
end
