local fs = require "nvim-lsp-installer.core.fs"
local notify = require "nvim-lsp-installer.notify"
local dispatcher = require "nvim-lsp-installer.dispatcher"
local process = require "nvim-lsp-installer.core.process"
local status_win = require "nvim-lsp-installer.ui"
local servers = require "nvim-lsp-installer.servers"
local settings = require "nvim-lsp-installer.settings"
local log = require "nvim-lsp-installer.log"
local platform = require "nvim-lsp-installer.core.platform"
local language_autocomplete_map = require "nvim-lsp-installer._generated.language_autocomplete_map"
local filetype_server_map = require "nvim-lsp-installer._generated.filetype_map"

local M = {}

M.settings = settings.set

---@param server_identifiers string[]
local function ensure_installed(server_identifiers)
    local candidates = {}
    for _, server_identifier in ipairs(server_identifiers) do
        local server_name, version = servers.parse_server_identifier(server_identifier)
        local ok, server = servers.get_server(server_name)
        if ok and not server:is_installed() then
            table.insert(candidates, server_name)
            server:install(version)
        end
    end
    if #candidates > 0 then
        notify("Installing LSP servers: " .. table.concat(candidates, ", "))
    end
end

---@param config LspInstallerSettings
function M.setup(config)
    if config then
        settings.set(config)
    end
    settings.uses_new_setup = true
    require("nvim-lsp-installer.middleware").register_lspconfig_hook()

    if vim.tbl_islist(settings.current.ensure_installed) then
        vim.schedule(function()
            ensure_installed(settings.current.ensure_installed)
        end)
    end
end

M.info_window = {
    ---Opens the status window.
    open = function()
        status_win().open()
    end,
    ---Closes the status window.
    close = function()
        status_win().close()
    end,
}

function M.get_install_completion()
    local result = {}
    local server_names = servers.get_available_server_names()
    vim.list_extend(result, server_names)
    vim.list_extend(result, vim.tbl_keys(language_autocomplete_map))
    return result
end

---Raises an error with the provided message. If in a headless environment,
---will also schedule an immediate shutdown with the provided exit code.
---@param msg string
---@param code number @The exit code to use when in headless mode.
local function raise_error(msg, code)
    if platform.is_headless then
        vim.schedule(function()
            -- We schedule the exit to make sure the call stack is exhausted
            os.exit(code or 1)
        end)
    end
    error(msg)
end

---Installs the provided servers synchronously (blocking call). It's recommended to only use this in headless environments.
---@param server_identifiers string[] @A list of server identifiers (for example {"rust_analyzer@nightly", "tsserver"}).
function M.install_sync(server_identifiers)
    local completed_servers = {}
    local failed_servers = {}
    local server_tuples = {}

    if vim.tbl_count(server_identifiers) == 0 then
        raise_error "No servers provided."
    end

    -- Collect all servers and exit early if unable to find one.
    for _, server_identifier in pairs(server_identifiers) do
        local server_name, version = servers.parse_server_identifier(server_identifier)
        local ok, server = servers.get_server(server_name)
        if not ok then
            raise_error(("Could not find server %q."):format(server_name))
        end
        table.insert(server_tuples, { server, version })
    end

    -- Start all installations.
    for _, server_tuple in ipairs(server_tuples) do
        local server, version = unpack(server_tuple)

        server:install_attached({
            stdio_sink = process.simple_sink(),
            requested_server_version = version,
        }, function(success)
            table.insert(completed_servers, server)
            if not success then
                table.insert(failed_servers, server)
            end
        end)
    end

    -- Poll for completion.
    if not vim.wait(60000 * 15, function()
        return #completed_servers >= #server_identifiers
    end, 100) then
        raise_error "Timed out waiting for server(s) to complete installing."
    end

    if #failed_servers > 0 then
        for _, server in pairs(failed_servers) do
            log.fmt_error("Server %s failed to install.", server.name)
        end
        raise_error(("%d/%d servers failed to install."):format(#failed_servers, #completed_servers))
    end

    for _, server in pairs(completed_servers) do
        log.fmt_info("Server %s was successfully installed.", server.name)
    end
end

---Unnstalls the provided servers synchronously (blocking call). It's recommended to only use this in headless environments.
---@param server_identifiers string[] @A list of server identifiers (for example {"rust_analyzer@nightly", "tsserver"}).
function M.uninstall_sync(server_identifiers)
    for _, server_identifier in pairs(server_identifiers) do
        local server_name = servers.parse_server_identifier(server_identifier)
        local ok, server = servers.get_server(server_name)
        if not ok then
            log.error(server)
            raise_error(("Could not find server %q."):format(server_name))
        end
        local uninstall_ok, uninstall_error = pcall(server.uninstall, server)
        if not uninstall_ok then
            log.error(tostring(uninstall_error))
            raise_error(("Failed to uninstall server %q."):format(server.name))
        end
        log.fmt_info("Successfully uninstalled server %s.", server.name)
    end
end

---@param server_name string
---@param callback fun(server_name: string, version: string|nil)
---@return string,string|nil
local function resolve_language_alias(server_name, callback)
    local language_aliases = language_autocomplete_map[server_name]
    if language_aliases then
        vim.ui.select(language_aliases, {
            prompt = ("Please select which %q server you want to install:"):format(server_name),
        }, function(choice)
            if choice then
                callback(choice)
            end
        end)
    else
        callback(server_name)
    end
end

---Will prompt the user via vim.ui.select() to select which server associated with the provided filetype to install.
---If the provided filetype is not associated with a server, an error message will be displayed.
---@param filetype string
function M.install_by_filetype(filetype)
    local servers_by_filetype = filetype_server_map[filetype]
    if servers_by_filetype then
        vim.ui.select(servers_by_filetype, {
            prompt = ("Please select which server you want to install for filetype %q:"):format(filetype),
        }, function(choice)
            if choice then
                M.install(choice)
            end
        end)
    else
        notify(("No LSP servers found for filetype %q"):format(filetype), vim.log.levels.WARN)
    end
end

--- Queues a server to be installed. Will also open the status window.
---@param server_identifier string @The server to install. This can also include a requested version, for example "rust_analyzer@nightly".
function M.install(server_identifier)
    local server_name, version = servers.parse_server_identifier(server_identifier)
    resolve_language_alias(server_name, function(resolved_server_name)
        if not resolved_server_name then
            -- No selection was made
            return
        end
        local ok, server = servers.get_server(resolved_server_name)
        if not ok then
            return notify(
                ("Unable to find LSP server %s.\n\n%s"):format(resolved_server_name, server),
                vim.log.levels.ERROR
            )
        end
        status_win().install_server(server, version)
        status_win().open()
    end)
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
function M.uninstall_all(no_confirm)
    if not no_confirm then
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

        if choice ~= 1 then
            print "Uninstalling all servers was aborted."
            return
        end
    end

    log.info "Uninstalling all servers."
    if fs.sync.dir_exists(settings.current.install_root_dir) then
        local ok, err = pcall(fs.sync.rmrf, settings.current.install_root_dir)
        if not ok then
            log.error(err)
            raise_error "Failed to uninstall all servers."
        end
    end
    log.info "Successfully uninstalled all servers."
    status_win().mark_all_servers_uninstalled()
    status_win().open()
end

---@deprecated Setup servers directly via lspconfig instead. See https://github.com/williamboman/nvim-lsp-installer/discussions/636
---@param cb fun(server: Server) @Callback to be executed whenever a server is ready to be set up.
function M.on_server_ready(cb)
    assert(
        not settings.uses_new_setup,
        "Please set up servers directly via lspconfig instead of using .on_server_ready() (this method is now deprecated)! Refer to :h nvim-lsp-installer-quickstart for more information."
    )
    dispatcher.register_server_ready_callback(cb)
    vim.schedule(function()
        local installed_servers = servers.get_installed_servers()
        for i = 1, #installed_servers do
            dispatcher.dispatch_server_ready(installed_servers[i])
        end
    end)
end

M.get_server = servers.get_server
M.get_available_servers = servers.get_available_servers
M.get_installed_servers = servers.get_installed_servers
M.get_uninstalled_servers = servers.get_uninstalled_servers
M.register = servers.register

return M
