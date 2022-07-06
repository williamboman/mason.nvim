local path = require "mason.core.path"

---@param install_dir string
return function(install_dir)
    return {
        cmd = { "java", "-jar", path.concat { install_dir, "build", "libs", "groovyls-all.jar" } },
    }
end
