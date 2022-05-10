local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.core.managers.std"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/dart-lang/sdk",
        languages = { "dart" },
        installer = std.system_executable("dart", { help_url = "https://dart.dev/get-dart" }),
        default_options = {},
    }
end
