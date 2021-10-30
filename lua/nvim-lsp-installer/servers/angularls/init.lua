local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

return function(name, root_dir)
    local util = require "lspconfig/util"
    --
    -- Angular requires a node_modules directory to probe for @angular/language-service and typescript
    -- in order to use your projects configured versions.
    -- This defaults to the vim cwd, but will get overwritten by the resolved root of the file.
    local function get_probe_dir(dir)
        local project_root = util.find_node_modules_ancestor(dir)

        return project_root and (project_root .. "/node_modules") or ""
    end

    local default_probe_dir = get_probe_dir(vim.fn.getcwd())
    local executable_path = npm.executable(root_dir, "ngserver")

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://angular.io/guide/language-service",
        installer = npm.packages { "@angular/language-server" },
        default_options = {
            cmd = {
                executable_path,
                "--stdio",
                "--tsProbeLocations",
                default_probe_dir,
                "--ngProbeLocations",
                default_probe_dir,
            },
            on_new_config = function(new_config, new_root_dir)
                local new_probe_dir = get_probe_dir(new_root_dir)

                -- We need to check our probe directories because they may have changed.
                new_config.cmd = {
                    executable_path,
                    "--stdio",
                    "--tsProbeLocations",
                    new_probe_dir,
                    "--ngProbeLocations",
                    new_probe_dir,
                }
            end,
        },
    }
end
