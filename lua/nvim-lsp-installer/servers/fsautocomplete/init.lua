local server = require "nvim-lsp-installer.server"
local dotnet = require "nvim-lsp-installer.core.managers.dotnet"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "f#" },
        homepage = "https://github.com/fsharp/FsAutoComplete",
        installer = dotnet.package "fsautocomplete",
        default_options = {
            cmd_env = dotnet.env(root_dir),
        },
    }
end
