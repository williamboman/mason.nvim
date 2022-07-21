local fs = require "mason-core.fs"
local path = require "mason-core.path"

---@param install_dir string
return function(install_dir)
    ---@param dir string
    local function get_tsserverlib_path(dir)
        return path.concat { dir, "node_modules", "typescript", "lib", "tsserverlibrary.js" }
    end

    ---@param workspace_dir string|nil
    local function get_typescript_server_path(workspace_dir)
        local local_tsserverlib = workspace_dir ~= nil and get_tsserverlib_path(workspace_dir)
        local vendored_tsserverlib = get_tsserverlib_path(install_dir)
        if local_tsserverlib and fs.sync.file_exists(local_tsserverlib) then
            return local_tsserverlib
        else
            return vendored_tsserverlib
        end
    end

    return {
        on_new_config = function(new_config, new_install_dir)
            new_config.init_options.typescript.serverPath = get_typescript_server_path(new_install_dir)
        end,
    }
end
