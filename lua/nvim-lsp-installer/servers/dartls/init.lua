local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/dart-lang/sdk",
        languages = { "dart" },
        installer = std.ensure_executables {
            {
                "dart",
                "dart was not found in path. Refer to https://dart.dev/get-dart for installation instructions.",
            },
        },
        default_options = {},
    }
end
