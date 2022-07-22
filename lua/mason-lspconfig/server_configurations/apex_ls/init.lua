local path = require "mason-core.path"

---@param config table
return function(config)
    local install_dir = config["install_dir"]

    return {
        apex_jar_path = path.concat { install_dir, "apex-jorje-lsp.jar" },
    }
end
