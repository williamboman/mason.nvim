local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.platform"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    local archive_name = coalesce(
        when(platform.is_mac, "rls-macos"),
        when(platform.is_linux, "rls-linux"),
        when(platform.is_win, "rls-windows")
    )
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "reason" },
        homepage = "https://github.com/jaredly/reason-language-server",
        installer = {
            context.use_github_release_file("jaredly/reason-language-server", ("%s.zip"):format(archive_name)),
            context.capture(function(ctx)
                return std.unzip_remote(ctx.github_release_file)
            end),
            context.capture(function()
                return std.rename(archive_name, "reason")
            end),
            context.receipt(function(receipt, ctx)
                receipt:with_primary_source(receipt.github_release_file(ctx))
            end),
        },
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "reason" } },
            },
        },
    }
end
