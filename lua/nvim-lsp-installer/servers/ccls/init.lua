local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local process = require "nvim-lsp-installer.core.process"

return function(name, root_dir)
    return server.Server:new {
        name = name,
        root_dir = root_dir,
        homepage = "https://github.com/MaskRay/ccls",
        languages = { "c", "c++", "objective-c" },
        installer = function()
            platform.when {
                mac = require "nvim-lsp-installer.servers.ccls.mac",
                linux = require "nvim-lsp-installer.servers.ccls.linux",
            }
        end,
        default_options = {
            cmd_env = {
                PATH = process.extend_path { path.concat { root_dir, "bin" } },
            },
        },
    }
end
