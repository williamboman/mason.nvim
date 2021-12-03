local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"
local Data = require "nvim-lsp-installer.data"
local path = require "nvim-lsp-installer.path"

local map = Data.list_map

local function append_node_modules(dirs)
    return map(function(dir)
        return path.concat { dir, "node_modules" }
    end, dirs)
end

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://angular.io/guide/language-service",
        languages = { "angular" },
        installer = npm.packages { "@angular/language-server", "typescript" },
        default_options = {
            on_new_config = function(new_config, new_root_dir)
                new_config.cmd = {
                    npm.executable(root_dir, "ngserver"),
                    "--stdio",
                    "--tsProbeLocations",
                    table.concat(append_node_modules { root_dir, new_root_dir }, ","),
                    "--ngProbeLocations",
                    table.concat(append_node_modules { root_dir, new_root_dir }, ","),
                }
            end,
        },
    }
end
