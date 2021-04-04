local installer = require('nvim-lsp-installer.installer')

local M = {}

M.get_available_servers = installer.get_available_servers
M.get_installed_servers = installer.get_installed_servers
M.get_uninstalled_servers = installer.get_uninstalled_servers
M.install = installer.install
M.uninstall = installer.uninstall

return M
