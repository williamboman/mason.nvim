local path = require "mason-core.path"

---@param install_dir string
return function(install_dir)
    return {
        apex_jar_path = path.concat { install_dir, "apex-jorje-lsp.jar" },
    }
end
