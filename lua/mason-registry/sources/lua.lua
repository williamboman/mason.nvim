local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"
local log = require "mason-core.log"

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
        id = spec.id,
        spec = spec,
    }, LuaRegistrySource)
end

---@param pkg_name string
---@return Package?
function LuaRegistrySource:get_package(pkg_name)
    local index = require(self.spec.mod)
    if index[pkg_name] then
        local ok, mod = pcall(require, index[pkg_name])
        if ok then
            return mod
        else
            log.fmt_warn("Unable to load %s from %s: %s", pkg_name, self, mod)
        end
    end
end

---@return string[]
function LuaRegistrySource:get_all_package_names()
    local index = require(self.spec.mod)
    return vim.tbl_keys(index)
end

---@return PackageSpec[]
function LuaRegistrySource:get_all_package_specs()
    return _.filter_map(function(name)
        return Optional.of_nilable(self:get_package(name)):map(_.prop "spec")
    end, self:get_all_package_names())
end

function LuaRegistrySource:is_installed()
    local ok = pcall(require, self.spec.mod)
    return ok
end

function LuaRegistrySource:get_installer()
    local Optional = require "mason-core.optional"
    return Optional.empty()
end

function LuaRegistrySource:get_display_name()
    if self:is_installed() then
        return ("require(%q)"):format(self.spec.mod)
    else
        return ("require(%q) [uninstalled]"):format(self.spec.mod)
    end
end

function LuaRegistrySource:__tostring()
    return ("LuaRegistrySource(mod=%s)"):format(self.spec.mod)
end

return LuaRegistrySource
