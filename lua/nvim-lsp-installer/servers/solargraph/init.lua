local server = require "nvim-lsp-installer.server"
local path = require "nvim-lsp-installer.path"
local zx = require "nvim-lsp-installer.installers.zx"

local root_dir = server.get_server_root_path "ruby"

return server.Server:new {
    name = "solargraph",
    root_dir = root_dir,
    installer = zx.file "./install.mjs",
    pre_install_check = function()
        if vim.fn.executable "bundle" ~= 1 then
            error "bundle not installed"
        end
    end,
    default_options = {
        cmd = { path.concat { root_dir, "solargraph", "solargraph" }, "stdio" },
    },
}
