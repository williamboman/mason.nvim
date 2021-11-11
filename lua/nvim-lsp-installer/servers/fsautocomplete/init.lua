local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local shell = require "nvim-lsp-installer.installers.shell"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "f#" },
        homepage = "https://github.com/fsharp/FsAutoComplete",
        installer = {
            std.ensure_executables {
                { "dotnet", "dotnet was not found in path." },
            },
            shell.polyshell [[dotnet tool update --tool-path . fsautocomplete]],
        },
        default_options = {
            cmd = {
                path.concat { root_dir, "fsautocomplete", "dotnet-fsautocomplete" },
                "--background-service-enabled",
            },
        },
    }
end
