local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local github = require "nvim-lsp-installer.core.managers.github"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "rescript" },
        homepage = "https://github.com/rescript-lang/rescript-vscode",
        installer = function()
            github.unzip_release_file({
                repo = "rescript-lang/rescript-vscode",
                asset_file = function(version)
                    return ("rescript-vscode-%s.vsix"):format(version)
                end,
            }).with_receipt()
        end,
        default_options = {
            cmd = { "node", path.concat { root_dir, "extension", "server", "out", "server.js" }, "--stdio" },
        },
    }
end
