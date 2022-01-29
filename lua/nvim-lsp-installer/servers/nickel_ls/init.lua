local path = require "nvim-lsp-installer.path"
local server = require "nvim-lsp-installer.server"
local std = require "nvim-lsp-installer.installers.std"
local context = require "nvim-lsp-installer.installers.context"
local cargo = require "nvim-lsp-installer.installers.cargo"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://nickel-lang.org/",
        languages = { "nickel" },
        installer = {
            std.git_clone "https://github.com/tweag/nickel",
            cargo.install {
                path = path.concat { "lsp", "nls" },
            },
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.git_remote "https://github.com/tweag/nickel")
            end),
        },
        default_options = {
            cmd_env = cargo.env(root_dir),
        },
    }
end
