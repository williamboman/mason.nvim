local a = require "nvim-lsp-installer.core.async"
local path = require "nvim-lsp-installer.core.path"
local server = require "nvim-lsp-installer.server"
local npm = require "nvim-lsp-installer.core.managers.npm"
local fs = require "nvim-lsp-installer.core.fs"

return function(name, root_dir)
    ---@param dir string
    local function get_tsserverlib_path(dir)
        return path.concat { dir, "node_modules", "typescript", "lib", "tsserverlibrary.js" }
    end

    ---@param workspace_dir string|nil
    local function get_typescript_server_path(workspace_dir)
        local local_tsserverlib = workspace_dir ~= nil and get_tsserverlib_path(workspace_dir)
        local vendored_tsserverlib = get_tsserverlib_path(root_dir)
        if local_tsserverlib and fs.sync.file_exists(local_tsserverlib) then
            return local_tsserverlib
        else
            return vendored_tsserverlib
        end
    end

    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/johnsoncodehk/volar",
        languages = { "vue" },
        installer = npm.packages { "@volar/vue-language-server", "typescript" },
        default_options = {
            cmd_env = npm.env(root_dir),
            on_new_config = function(new_config, new_root_dir)
                new_config.init_options.typescript.serverPath = get_typescript_server_path(new_root_dir)
            end,
        },
    }
end
