local server = require "nvim-lsp-installer.server"
local platform = require "nvim-lsp-installer.core.platform"
local npm = require "nvim-lsp-installer.core.managers.npm"
local _ = require "nvim-lsp-installer.core.functional"
local path = require "nvim-lsp-installer.core.path"

local append_node_modules = _.map(function(dir)
    return path.concat { dir, "node_modules" }
end)

return function(name, root_dir)
    local function get_cmd(workspace_dir)
        local cmd = {
            "ngserver",
            "--stdio",
            "--tsProbeLocations",
            table.concat(append_node_modules { root_dir, workspace_dir }, ","),
            "--ngProbeLocations",
            table.concat(
                append_node_modules {
                    path.concat { root_dir, "node_modules", "@angular", "language-server" },
                    workspace_dir,
                },
                ","
            ),
        }
        if platform.is_win then
            table.insert(cmd, 1, "cmd.exe")
            table.insert(cmd, 2, "/C")
        end

        return cmd
    end

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://angular.io/guide/language-service",
        languages = { "angular" },
        installer = npm.packages { "@angular/language-server", "typescript" },
        default_options = {
            cmd = get_cmd(path.cwd()),
            cmd_env = npm.env(root_dir),
            on_new_config = function(new_config, new_root_dir)
                new_config.cmd = get_cmd(new_root_dir)
            end,
        },
    }
end
