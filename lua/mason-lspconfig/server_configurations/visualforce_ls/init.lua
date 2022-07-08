local path = require "mason-core.path"

---@param install_dir string
return function(install_dir)
    return {
        cmd = {
            "node",
            path.concat {
                install_dir,
                "extension",
                "node_modules",
                "@salesforce",
                "salesforcedx-visualforce-language-server",
                "out",
                "src",
                "visualforceServer.js",
            },
            "--stdio",
        },
    }
end
