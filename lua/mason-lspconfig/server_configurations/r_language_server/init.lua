local path = require "mason-core.path"

---@param install_dir string
return function(install_dir)
    return {
        cmd = { "R", "--slave", "-f", path.concat { install_dir, "server.R" } },
    }
end
