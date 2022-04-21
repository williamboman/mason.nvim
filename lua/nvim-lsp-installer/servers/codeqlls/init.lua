local server = require "nvim-lsp-installer.server"
local Data = require "nvim-lsp-installer.data"
local platform = require "nvim-lsp-installer.platform"
local github = require "nvim-lsp-installer.core.managers.github"
local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"

local coalesce, when = Data.coalesce, Data.when

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "codeql" },
        async = true,
        installer = function()
            github.unzip_release_file({
                repo = "github/codeql-cli-binaries",
                asset_file = coalesce(
                    when(platform.is_mac, "codeql-osx64.zip"),
                    when(platform.is_unix, "codeql-linux64.zip"),
                    when(platform.is_win, "codeql-win64.zip")
                ),
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "codeql" } },
            },
        },
    }
end
