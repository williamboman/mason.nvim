local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"

---@param languages string[]
return function(languages)
    return function(name, root_dir)
        return server.Server:new {
            name = name,
            languages = languages,
            root_dir = root_dir,
            installer = npm.packages { "vscode-langservers-extracted" },
            default_options = {
                cmd_env = npm.env(root_dir),
            },
        }
    end
end
