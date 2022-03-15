local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local std = require "nvim-lsp-installer.installers.std"
local npm = require "nvim-lsp-installer.installers.npm"
local context = require "nvim-lsp-installer.installers.context"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "ansible" },
        homepage = "https://github.com/ansible/ansible-language-server",
        installer = {
            std.git_clone "https://github.com/ansible/ansible-language-server",
            npm.install { "npm@latest" }, -- ansiblels has quite a strict npm version requirement
            npm.exec(npm.npm_command, { "install" }),
            npm.run "compile",
            context.receipt(function(receipt)
                receipt:with_primary_source(receipt.git_remote "https://github.com/ansible/ansible-language-server")
            end),
        },
        default_options = {
            cmd = { "node", path.concat { root_dir, "out", "server", "src", "server.js" }, "--stdio" },
        },
    }
end
