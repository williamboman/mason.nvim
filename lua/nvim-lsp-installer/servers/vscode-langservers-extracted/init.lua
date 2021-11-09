local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.installers.npm"

---@param executable string @The vscode-langservers-extracted executable to use for the server.
---@param languages string[]
return function(executable, languages)
    return function(name, root_dir)
        return server.Server:new {
            name = name,
            languages = languages,
            root_dir = root_dir,
            installer = npm.packages { "vscode-langservers-extracted" },
            default_options = {
                cmd = { npm.executable(root_dir, executable), "--stdio" },
            },
        }
    end
end
