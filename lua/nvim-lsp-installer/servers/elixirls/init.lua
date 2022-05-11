local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local github = require "nvim-lsp-installer.core.managers.github"
local std = require "nvim-lsp-installer.core.managers.std"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/elixir-lsp/elixir-ls",
        languages = { "elixir" },
        ---@param ctx InstallContext
        installer = function(ctx)
            -- We write to the elixir-ls directory for backwards compatibility reasons
            ctx.fs:mkdir "elixir-ls"
            ctx:chdir("elixir-ls", function()
                github.unzip_release_file({
                    repo = "elixir-lsp/elixir-ls",
                    asset_file = "elixir-ls.zip",
                }).with_receipt()
                std.chmod("+x", { "language_server.sh" })
            end)
        end,
        default_options = {
            cmd = {
                path.concat {
                    root_dir,
                    "elixir-ls",
                    platform.is_win and "language_server.bat" or "language_server.sh",
                },
            },
        },
    }
end
