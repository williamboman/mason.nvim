local path = require "mason-core.path"

---@param install_dir string
return function(install_dir)
    return {
        cmd = {
            "node",
            path.concat { install_dir, "node_modules", "perlnavigator-server", "out", "server.js" },
            "--stdio",
        },
    }
end
