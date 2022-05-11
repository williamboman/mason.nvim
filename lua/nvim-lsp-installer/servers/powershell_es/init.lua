local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local std = require "nvim-lsp-installer.core.managers.std"
local github = require "nvim-lsp-installer.core.managers.github"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/PowerShell/PowerShellEditorServices",
        languages = { "powershell" },
        installer = function()
            std.ensure_executable("pwsh", { help_url = "https://github.com/PowerShell/PowerShell#get-powershell" })
            github.unzip_release_file({
                repo = "PowerShell/PowerShellEditorServices",
                asset_file = "PowerShellEditorServices.zip",
            }).with_receipt()
        end,
        default_options = {
            bundle_path = path.concat { root_dir },
        },
    }
end
