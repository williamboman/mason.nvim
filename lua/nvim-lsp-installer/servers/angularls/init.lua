local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://angular.io/guide/language-service",
        languages = { "angular" },
        installer = npm.packages { "@angular/language-server", "typescript" },
        default_options = {
            cmd = {
                npm.executable(root_dir, "ngserver"),
                "--stdio",
                "--tsProbeLocations",
                root_dir,
                "--ngProbeLocations",
                root_dir,
            },
        },
    }
end
