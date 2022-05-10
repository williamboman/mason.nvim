local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        languages = { "solidity" },
        homepage = "https://github.com/edag94/vscode-solidity",
        installer = npm.packages { "solidity-language-server" },
        default_options = {
            cmd_env = npm.env(root_dir),
        },
    }
end
