local server = require "nvim-lsp-installer.server"
local dotnet = require "nvim-lsp-installer.core.managers.dotnet"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "c#" },
        homepage = "https://github.com/razzmatazz/csharp-language-server",
        installer = dotnet.package "csharp-ls",
        default_options = {
            cmd_env = dotnet.env(root_dir),
        },
    }
end
