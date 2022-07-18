local log = require "mason-core.log"
local Package = require "mason-core.package"
local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"
local settings = require "mason-lspconfig.settings"
local server_mapping = require "mason-lspconfig.mappings.server"
local path = require "mason-core.path"
local registry = require "mason-registry"
local notify = require "mason-core.notify"

local M = {}

---@param lspconfig_server_name string
local function resolve_package(lspconfig_server_name)
    return Optional.of_nilable(server_mapping.lspconfig_to_package[lspconfig_server_name]):map(function(package_name)
        local ok, pkg = pcall(registry.get_package, package_name)
        if ok then
            return pkg
        end
    end)
end

---@param lspconfig_server_name string
local function resolve_server_config_factory(lspconfig_server_name)
    local ok, server_config = pcall(require, ("mason-lspconfig.server_configurations.%s"):format(lspconfig_server_name))
    if ok then
        return Optional.of(server_config)
    end
    return Optional.empty()
end

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

local memoized_set = _.memoize(_.set_of)

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

local expand_cmd = {
    ["angularls"] = true,
    ["arduino_language_server"] = true,
    ["asm_lsp"] = true,
    ["beancount"] = true,
    ["bicep"] = true,
    ["bsl_ls"] = true,
    ["ccls"] = true,
    ["clangd"] = true,
    ["clarity_lsp"] = true,
    ["clojure_lsp"] = true,
    ["cmake"] = true,
    ["codeqlls"] = true,
    ["crystalline"] = true,
}

local function setup_lspconfig_hook()
    local util = require "lspconfig.util"
    util.on_setup = util.add_hook_before(util.on_setup, function(config)
        local pkg_name = server_mapping.lspconfig_to_package[config.name]
        if not pkg_name then
            return
        end

        if registry.is_installed(pkg_name) then
            resolve_server_config_factory(config.name):if_present(function(config_factory)
                merge_in_place(config, config_factory({ install_dir = path.package_prefix(pkg_name) }, config))
                if expand_cmd[config.name] and config.cmd and config.cmd[1] then
                    local exepath = vim.fn.exepath(config.cmd[1])
                    if exepath ~= "" then
                        config.cmd[1] = exepath
                    else
                        log.error("Failed to expand cmd path", config.name, config.cmd)
                    end
                end
            end)
        else
            if should_auto_install(config.name) then
                local pkg = registry.get_package(pkg_name)
                pkg:install()
            end
        end
    end)
end

local function ensure_installed()
    for _, server_identifier in ipairs(settings.current.ensure_installed) do
        local server_name, version = Package.Parse(server_identifier)
        resolve_package(server_name):if_present(
            ---@param pkg Package
            function(pkg)
                if not pkg:is_installed() then
                    pkg:install {
                        version = version,
                    }
                end
            end
        )
    end
end

---@param config MasonLspconfigSettings | nil
function M.setup(config)
    if config then
        settings.set(config)
    end

    setup_lspconfig_hook()
    ensure_installed()

    require "mason-lspconfig.api.command"
end

---See `:h mason-lspconfig.setup_handlers()`
---@param handlers table<string, fun(server_name: string)>
function M.setup_handlers(handlers)
    local default_handler = Optional.of_nilable(handlers[1])

    _.each(function(handler)
        if type(handler) == "string" and not server_mapping.lspconfig_to_package[handler] then
            notify(
                ("mason-lspconfig.setup_handlers: Received handler for unknown lspconfig server name: %s."):format(
                    handler
                ),
                vim.log.levels.WARN
            )
        end
    end, _.keys(handlers))

    ---@param pkg_name string
    local function get_server_name(pkg_name)
        return Optional.of_nilable(server_mapping.package_to_lspconfig[pkg_name])
    end

    local function call_handler(server_name)
        log.fmt_trace("Checking handler for %s", server_name)
        Optional.of_nilable(handlers[server_name]):or_(_.always(default_handler)):if_present(function(handler)
            log.fmt_trace("Calling handler for %s", server_name)
            local ok, err = pcall(handler, server_name)
            if not ok then
                vim.notify(err, vim.log.levels.ERROR)
            end
        end)
    end

    local installed_servers = _.filter_map(get_server_name, registry.get_installed_package_names())
    _.each(call_handler, installed_servers)
    registry:on(
        "package:install:success",
        vim.schedule_wrap(function(pkg)
            get_server_name(pkg.name):if_present(call_handler)
        end)
    )
end

---@return string[]
function M.get_installed_servers()
    return _.filter_map(function(pkg_name)
        return Optional.of_nilable(server_mapping.package_to_lspconfig[pkg_name])
    end, registry.get_installed_package_names())
end

return M
