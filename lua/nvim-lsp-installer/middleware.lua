local util = require "lspconfig.util"
local _ = require "nvim-lsp-installer.core.functional"
local notify = require "nvim-lsp-installer.notify"
local servers = require "nvim-lsp-installer.servers"
local settings = require "nvim-lsp-installer.settings"
local functional = require "nvim-lsp-installer.core.functional"

local memoize, set_of = functional.memoize, functional.set_of

local M = {}

---@param t1 table
---@param t2 table
local function merge_in_place(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k]) == "table" and not vim.tbl_islist(t1[k]) then
                merge_in_place(t1[k], v)
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

local memoized_set = memoize(set_of)

---@param server_name string
local function should_auto_install(server_name)
    if settings.current.automatic_installation == true then
        return true
    end
    if type(settings.current.automatic_installation) == "table" then
        return not memoized_set(settings.current.automatic_installation.exclude)[server_name]
    end
    return false
end

local registered_server_hooks = {}

---@param server_name string
---@param fn fun(config: table)
function M.register_server_hook(server_name, fn)
    if not registered_server_hooks[server_name] then
        registered_server_hooks[server_name] = {}
    end
    table.insert(registered_server_hooks[server_name], fn)
end

function M.register_lspconfig_hook()
    util.on_setup = util.add_hook_before(util.on_setup, function(config)
        local ok, server = servers.get_server(config.name)
        if ok then
            if server:is_installed() then
                merge_in_place(config, server._default_options)
            elseif should_auto_install(server.name) then
                notify("(automatic installation) Installing LSP server: " .. server.name)
                server:install()
            end
        end

        if registered_server_hooks[config.name] then
            _.each(function(fn)
                local ok, err = pcall(fn, config)
                if not ok then
                    notify(err, vim.log.levels.ERROR)
                end
            end, registered_server_hooks[config.name])
        end
    end)
end

return M
