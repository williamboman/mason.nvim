local notify = require "nvim-lsp-installer.notify"
local dispatcher = require "nvim-lsp-installer.dispatcher"
local process = require "nvim-lsp-installer.process"
local status_win = require "nvim-lsp-installer.ui.status-win"
local servers = require "nvim-lsp-installer.servers"

local M = {}

function M.display()
    status_win().open()
end

function M.install(server_name)
    local ok, server = servers.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    status_win().install_server(server)
    status_win().open()
end

function M.uninstall(server_name)
    local ok, server = servers.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    status_win().uninstall_server(server)
    status_win().open()
end

function M.uninstall_all()
    local installed_servers = servers.get_installed_servers()
    status_win().open()
    if #installed_servers > 0 then
        local function uninstall(idx)
            status_win().uninstall_server(installed_servers[idx])
            if installed_servers[idx + 1] then
                vim.schedule(function()
                    uninstall(idx + 1)
                end)
            end
        end
        uninstall(1)
    end
end

function M.on_server_ready(cb)
    dispatcher.register_server_ready_callback(cb)
    vim.schedule(function()
        local installed_servers = servers.get_installed_servers()
        for i = 1, #installed_servers do
            dispatcher.dispatch_server_ready(installed_servers[i])
        end
    end)
end

-- "Proxy" function for triggering attachment of LSP servers to all buffers (useful when just installed a new server
-- that wasn't installed at launch)
M.lsp_attach_proxy = process.debounced(function()
    -- As of writing, if the lspconfig server provides a filetypes setting, it uses FileType as trigger, otherwise it uses BufReadPost
    vim.cmd [[ doautoall FileType | doautoall BufReadPost ]]
end)

-- old API
M.get_server = servers.get_server
M.get_available_servers = servers.get_available_servers
M.get_installed_servers = servers.get_installed_servers
M.get_uninstalled_servers = servers.get_uninstalled_servers
M.register = servers.register

return M
