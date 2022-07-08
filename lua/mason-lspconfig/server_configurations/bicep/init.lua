local path = require "mason-core.path"

---@param install_dir string
return function(install_dir)
    return {
        cmd = { "dotnet", path.concat { install_dir, "Bicep.LangServer.dll" } },
    }
end
