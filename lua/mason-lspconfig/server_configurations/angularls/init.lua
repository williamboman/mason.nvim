local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local path = require "mason-core.path"

---@param install_dir string
return function(install_dir)
    local append_node_modules = _.map(function(dir)
        return path.concat { dir, "node_modules" }
    end)

    local function get_cmd(workspace_dir)
        local cmd = {
            "ngserver",
            "--stdio",
            "--tsProbeLocations",
            table.concat(append_node_modules { install_dir, workspace_dir }, ","),
            "--ngProbeLocations",
            table.concat(
                append_node_modules {
                    path.concat { install_dir, "node_modules", "@angular", "language-server" },
                    workspace_dir,
                },
                ","
            ),
        }
        if platform.is_win then
            cmd[1] = vim.fn.exepath(cmd[1])
        end

        return cmd
    end

    return {
        cmd = get_cmd(vim.loop.cwd()),
        on_new_config = function(new_config, root_dir)
            new_config.cmd = get_cmd(root_dir)
        end,
    }
end
