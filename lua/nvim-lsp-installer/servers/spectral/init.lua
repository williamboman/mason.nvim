local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"
local std = require "nvim-lsp-installer.installers.std"
local installers = require "nvim-lsp-installer.installers"
local context = require "nvim-lsp-installer.installers.context"
local path = require "nvim-lsp-installer.path"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "openapi", "asyncapi" },
        homepage = "https://stoplight.io/open-source/spectral/",
        installer = {
            std.git_clone "https://github.com/stoplightio/vscode-spectral",
            npm.install(),
            installers.branch_context {
                context.set_working_dir "server",
                npm.install(),
            },
            installers.always_succeed(npm.run "compile"),
            context.set_working_dir "server",
            context.receipt(function(receipt, ctx)
                receipt
                    :mark_invalid() -- Due to the `context.set_working_dir` after clone, we essentially erase any trace of the cloned git repo, so we mark this as invalid.
                    :with_primary_source(receipt.git_remote "https://github.com/stoplightio/vscode-spectral")
            end),
        },
        default_options = {
            cmd = { "node", path.concat { root_dir, "out", "server.js" }, "--stdio" },
        },
    }
end
