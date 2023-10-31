local _ = require "mason-core.functional"

local M = {}

---@param str string
local function split_once_left(str, char)
    for i = 1, #str do
        if str:sub(i, i) == char then
            local segment = str:sub(1, i - 1)
            return segment, str:sub(i + 1)
        end
    end
    return str
end

---@param registry_id string
---@return fun(): RegistrySource # Thunk to instantiate provider.
local function parse(registry_id)
    local type, id = split_once_left(registry_id, ":")
    if type == "github" then
        local namespace, name = id:match "^(.+)/(.+)$"
        if not namespace or not name then
            error(("Failed to parse repository from GitHub registry: %q."):format(registry_id), 0)
        end
        local name, version = unpack(vim.split(name, "@"))
        return function()
            local GitHubRegistrySource = require "mason-registry.sources.github"
            return GitHubRegistrySource.new {
                id = registry_id,
                repo = ("%s/%s"):format(namespace, name),
                namespace = namespace,
                name = name,
                version = version,
            }
        end
    elseif type == "lua" then
        return function()
            local LuaRegistrySource = require "mason-registry.sources.lua"
            return LuaRegistrySource.new {
                id = registry_id,
                mod = id,
            }
        end
    elseif type == "file" then
        return function()
            local FileRegistrySource = require "mason-registry.sources.file"
            return FileRegistrySource.new {
                path = id,
            }
        end
    elseif type ~= nil then
        error(("Unknown registry type %q: %q."):format(type, registry_id), 0)
    end
    error(("Malformed registry id: %q."):format(registry_id), 0)
end

---@type ((fun(): RegistrySource) | RegistrySource)[]
local registries = {}

---@param registry_ids string[]
function M.set_registries(registry_ids)
    registries = {}
    for _, registry in ipairs(registry_ids) do
        local ok, err = pcall(function()
            table.insert(registries, parse(registry))
        end)
        if not ok then
            local log = require "mason-core.log"
            local notify = require "mason-core.notify"
            log.fmt_error("Failed to parse registry %q: %s", registry, err)
            notify(err, vim.log.levels.ERROR)
        end
    end
end

---@param opts? { include_uninstalled?: boolean }
function M.iter(opts)
    opts = opts or {}
    local i = 1
    return function()
        while i <= #registries do
            local registry = registries[i]
            if type(registry) == "function" then
                -- unwrap thunk
                registry = registry()
                registries[i] = registry
            end
            i = i + 1
            if opts.include_uninstalled or registry:is_installed() then
                return registry
            end
        end
    end
end

---@return boolean #Returns true if all sources are installed.
function M.is_installed()
    for source in M.iter { include_uninstalled = true } do
        if not source:is_installed() then
            return false
        end
    end
    return true
end

---@return string # The sha256 checksum of the currently registered sources.
function M.checksum()
    ---@type string[]
    local registry_ids = {}
    for source in M.iter { include_uninstalled = true } do
        table.insert(registry_ids, source.id)
    end
    local checksum = _.compose(vim.fn.sha256, _.join "", _.sort_by(_.identity))
    return checksum(registry_ids)
end

return M
