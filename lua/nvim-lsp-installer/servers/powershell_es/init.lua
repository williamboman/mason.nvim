local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local installers = require "nvim-lsp-installer.installers"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/PowerShell/PowerShellEditorServices",
        languages = { "powershell" },
        installer = installers.when {
            win = {
                context.use_github_release_file("PowerShell/PowerShellEditorServices", "PowerShellEditorServices.zip"),
                context.capture(function(ctx)
                    return std.unzip_remote(ctx.github_release_file)
                end),
            },
        },
        default_options = {
            bundle_path = path.concat { root_dir },
        },
    }
end
