local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        installer = installers.when {
            unix = shell.remote_bash("https://deno.land/x/install/install.sh", {
                env = {
                    DENO_INSTALL = root_dir,
                },
            }),
            win = shell.remote_powershell("https://deno.land/x/install/install.ps1", {
                env = {
                    DENO_INSTALL = root_dir,
                },
            }),
        },
        default_options = {
            cmd = { path.concat { root_dir, "bin", "deno" }, "lsp" },
        },
    }
end
