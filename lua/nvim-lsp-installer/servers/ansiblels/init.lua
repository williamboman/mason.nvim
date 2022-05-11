local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local npm = require "nvim-lsp-installer.core.managers.npm"
local git = require "nvim-lsp-installer.core.managers.git"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "ansible" },
        homepage = "https://github.com/ansible/ansible-language-server",
        installer = function()
            git.clone({ "https://github.com/ansible/ansible-language-server" }).with_receipt()
            -- ansiblels has quite a strict npm version requirement.
            -- Install dependencies using the the latest npm version.
            npm.exec { "npm@latest", "install" }
            npm.run { "compile" }
        end,
        default_options = {
            cmd = { "node", path.concat { root_dir, "out", "server", "src", "server.js" }, "--stdio" },
        },
    }
end
