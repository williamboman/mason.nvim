local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/apple/sourcekit-lsp",
        languages = { "swift" },
        installer = {
            std.ensure_executables {
                {
                    "sourcekit-lsp",
                    "sourcekit-lsp was not found in path. Refer to https://github.com/apple/sourcekit-lsp for installation instructions.",
                },
            },
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.system "sourcekit-lsp")
            end),
        },
        default_options = {},
    }
end
