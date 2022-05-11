local server = require "nvim-lsp-installer.server"
local process = require "nvim-lsp-installer.core.process"
local path = require "nvim-lsp-installer.core.path"
local github = require "nvim-lsp-installer.core.managers.github"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/fwcd/kotlin-language-server",
        languages = { "kotlin" },
        installer = function()
            github.unzip_release_file({
                repo = "fwcd/kotlin-language-server",
                asset_file = "server.zip",
            }).with_receipt()
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path {
                    path.concat {
                        root_dir,
                        "server",
                        "bin",
                    },
                },
            },
        },
    }
end
