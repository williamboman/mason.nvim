local server = require "nvim-lsp-installer.server"
local cargo = require "nvim-lsp-installer.core.managers.cargo"

return function(name, root_dir)
    local homepage = "https://github.com/wgsl-analyzer/wgsl-analyzer"

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "wgsl" },
        homepage = homepage,
        installer = cargo.crate("wgsl_analyzer", {
            git = homepage,
        }),
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
