---@class LuaRegistrySourceSpec
---@field id string
---@field mod string

---@class LuaRegistrySource : RegistrySource
---@field private spec LuaRegistrySourceSpec
local LuaRegistrySource = {}
LuaRegistrySource.__index = LuaRegistrySource

---@param spec LuaRegistrySourceSpec
function LuaRegistrySource.new(spec)
    return setmetatable({
        spec = spec,
    }, LuaRegistrySource)
end

---@param pkg_name string
---@return Package?
function LuaRegistrySource:get_package(pkg_name)
    local index = require(self.spec.mod)
    if index[pkg_name] then
        return require(index[pkg_name])
    end
end

---@return string[]
function LuaRegistrySource:get_all_package_names()
    local index = require(self.spec.mod)
    return vim.tbl_keys(index)
end

function LuaRegistrySource:is_installed()
    local ok = pcall(require, self.spec.mod)
    return ok
end

function LuaRegistrySource:install()
    local Result = require "mason-core.result"
    return Result.success()
end

function LuaRegistrySource:__tostring()
    return ("LuaRegistrySource(mod=%s)"):format(self.spec.mod)
end

return LuaRegistrySource
