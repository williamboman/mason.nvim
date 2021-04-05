local server = require('nvim-lsp-installer.server')

local M = {}

M.get_available_servers = server.get_available_servers
M.get_installed_servers = server.get_installed_servers
M.get_uninstalled_servers = server.get_uninstalled_servers
M.install = server.install
M.uninstall = server.uninstall

return M
