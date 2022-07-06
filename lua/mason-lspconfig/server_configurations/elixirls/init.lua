local path = require "mason.core.path"
local platform = require "mason.core.platform"

---@param install_dir string
return function(install_dir)
    return {
        cmd = {
            path.concat {
                install_dir,
                "elixir-ls",
                platform.is_win and "language_server.bat" or "language_server.sh",
            },
        },
    }
end
