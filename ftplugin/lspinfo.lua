local servers = require "nvim-lsp-installer.servers"
local functional = require "nvim-lsp-installer.core.functional"
local log = require "nvim-lsp-installer.log"

local filter, compose = functional.filter, functional.compose

---@class LspInfoClient
---@field name string
---@field cmd string[]
---@field cmd_diagnostics {lineno: integer}|nil

---@param client LspInfoClient
local function is_client_managed(client)
    local ok, server = servers.get_server(client.name)
    return ok and server:is_installed()
end

---@param client LspInfoClient
local function client_has_cmd_diagnostics(client)
    return client.cmd_diagnostics ~= nil
end

---@param client LspInfoClient
local function client_has_cmd(client)
    return client.cmd ~= nil
end

---@param client LspInfoClient[]
local function is_cmd_executable(client)
    local cmd = client.cmd[1]
    local ok, server = servers.get_server(client.name)
    if not ok then
        -- should not really happen
        return false
    end
    local options = server:get_default_options()
    local path = options.cmd_env and options.cmd_env.PATH
    if path then
        local old_path = vim.env.PATH
        local is_executable = pcall(function()
            vim.env.PATH = path
            assert(vim.fn.executable(cmd) == 1)
        end)
        vim.env.PATH = old_path
        return is_executable
    else
        return vim.fn.executable(cmd) == 1
    end
end

local ok, err = pcall(function()
    ---@type LspInfoClient[]
    local clients = {}

    local lines = vim.api.nvim_buf_get_lines(0, 1, -1, false)

    local function parse_line(line)
        local client_name = line:match "^%s+Client:%s+(.+)%s+%(.*$"
        if client_name then
            return "client_header", client_name
        end

        local config_name = line:match "^%s+Config:%s+(.+)$"
        if config_name then
            return "client_header", config_name
        end

        local cmd_diagnostics = line:match "^%s+cmd is executable:.*$"
        if cmd_diagnostics then
            return "cmd_diagnostics"
        end

        local cmd = line:match "^%s+cmd:%s+(.+)$"
        if cmd then
            return "cmd", vim.split(cmd, "%s")
        end
    end

    local current_client
    for lineno, line in ipairs(lines) do
        local type, value = parse_line(line)
        if type == "client_header" then
            current_client = { name = value }
            table.insert(clients, current_client)
        elseif type == "cmd_diagnostics" then
            current_client.cmd_diagnostics = { lineno = lineno }
        elseif type == "cmd" then
            current_client.cmd = value
        end
    end

    ---@type LspInfoClient[]
    local executable_clients = compose(
        filter(is_cmd_executable),
        filter(client_has_cmd),
        filter(client_has_cmd_diagnostics),
        filter(is_client_managed)
    )(clients)

    local override_cmd_diagnostics = functional.partial(functional.each, function(client)
        vim.api.nvim_buf_set_lines(
            0,
            client.cmd_diagnostics.lineno,
            client.cmd_diagnostics.lineno + 1,
            false,
            { " 	cmd is executable: true (checked by nvim-lsp-installer)" }
        )
    end)

    vim.api.nvim_buf_set_option(0, "modifiable", true)
    override_cmd_diagnostics(executable_clients)
    vim.api.nvim_buf_set_option(0, "modifiable", false)
end)

if not ok then
    log.error("Failed to patch :LspInfo window", err)
end
