local fs = require "nvim-lsp-installer.fs"
local notify = require "nvim-lsp-installer.notify"
local dispatcher = require "nvim-lsp-installer.dispatcher"
local process = require "nvim-lsp-installer.process"
local status_win = require "nvim-lsp-installer.ui.status-win"
local servers = require "nvim-lsp-installer.servers"
local settings = require "nvim-lsp-installer.settings"
local log = require "nvim-lsp-installer.log"

local M = {}

M.settings = settings.set

--- Opens the status window.
function M.display()
    status_win().open()
end

--- Queues a server to be installed. Will also open the status window.
--- Use the .on_server_ready(cb) function to register a handler to be executed when a server is ready to be set up.
---@param server_identifier string @The server to install. This can also include a requested version, for example "rust_analyzer@nightly".
function M.install(server_identifier)
    local server_name, version = unpack(servers.parse_server_identifier(server_identifier))
    local ok, server = servers.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    status_win().install_server(server, version)
    status_win().open()
end

--- Queues a server to be uninstalled. Will also open the status window.
---@param server_name string The server to uninstall.
function M.uninstall(server_name)
    local ok, server = servers.get_server(server_name)
    if not ok then
        return notify(("Unable to find LSP server %s.\n\n%s"):format(server_name, server), vim.log.levels.ERROR)
    end
    status_win().uninstall_server(server)
    status_win().open()
end

--- Queues all servers to be uninstalled. Will also open the status window.
function M.uninstall_all()
    local choice = vim.fn.confirm(
        ("This will uninstall all servers currently installed at %q. Continue?"):format(
            vim.fn.fnamemodify(settings.current.install_root_dir, ":~")
        ),
        "&Yes\n&No",
        2
    )
    if settings.current.install_root_dir ~= settings._DEFAULT_SETTINGS.install_root_dir then
        choice = vim.fn.confirm(
            (
                "WARNING: You are using a non-default install_root_dir (%q). This command will delete the entire directory. Continue?"
            ):format(vim.fn.fnamemodify(settings.current.install_root_dir, ":~")),
            "&Yes\n&No",
            2
        )
    end
    if choice == 1 then
        log.info "Uninstalling all servers."
        status_win().open()
        vim.schedule(function()
            if fs.dir_exists(settings.current.install_root_dir) then
                fs.rmrf(settings.current.install_root_dir)
                status_win().mark_all_servers_uninstalled()
            end
        end)
    else
        print "Uninstalling all servers was aborted."
    end
end

---@param cb fun(server: Server) @Callback to be executed whenever a server is ready to be set up.
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
