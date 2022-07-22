local path = require "mason-core.path"
local process = require "mason-core.process"

---@param config table
return function(config)
    local install_dir = config["install_dir"]

    return {
        cmd_env = {
            PATH = process.extend_path {
                path.concat { install_dir, "llvm13.0", "bin" },
                path.concat { install_dir, "llvm12.0", "bin" }, -- kept for backwards compatibility
            },
        },
    }
end
