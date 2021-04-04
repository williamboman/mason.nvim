local installer = require('nvim-lsp-installer.installer')

local M = {}

M.get_available_servers = installer.get_available_servers
M.get_installed_servers = installer.get_installed_servers
M.get_uninstalled_servers = installer.get_uninstalled_servers
M.install = installer.install
M.uninstall = installer.uninstall

function M.get_installer(server, only_installed)
    only_installed = only_installed ~= nil and only_installed or false
    local pool = only_installed and installer.get_installed_servers() or installer.get_available_servers()

    for _, server_installer in pairs(pool) do
        if server_installer.name == server then
            return server_installer
        end
    end
    return nil
end

return M
