local M = {}

---@param registry_id string
---@return fun(): RegistrySource # Thunk to instantiate provider.
local function parse(registry_id)
    local type, id = registry_id:match "^(.+):(.+)$"
    if type == "lua" then
        return function()
            local LuaRegistrySource = require "mason-registry.sources.lua"
            return LuaRegistrySource.new {
                id = registry_id,
                mod = id,
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
    for _, registry in ipairs(registry_ids) do
        local ok, err = pcall(function()
            table.insert(registries, parse(registry))
        end)
        if not ok then
            local log = require "mason-core.log"
            local notify = require "mason-core.notify"
            log.fmt_error("Failed to parse registry %q: %s", registry, err)
            notify(err)
        end
    end
end

function M.iter()
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
            if registry:is_installed() then
                return registry
            end
        end
    end
end

return M
