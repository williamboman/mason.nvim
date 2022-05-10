local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.core.managers.std"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/apple/sourcekit-lsp",
        languages = { "swift" },
        installer = std.system_executable("sourcekit-lsp", { help_url = "https://github.com/apple/sourcekit-lsp" }),
        default_options = {},
    }
end
