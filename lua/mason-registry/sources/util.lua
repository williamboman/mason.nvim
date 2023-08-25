local Optional = require "mason-core.optional"
local Pkg = require "mason-core.package"
local _ = require "mason-core.functional"
local log = require "mason-core.log"
local registry_installer = require "mason-core.installer.registry"

local M = {}

---@param spec RegistryPackageSpec
function M.map_registry_spec(spec)
    spec.schema = spec.schema or "registry+v1"

    if not registry_installer.SCHEMA_CAP[spec.schema] then
        log.fmt_debug("Excluding package=%s with unsupported schema_version=%s", spec.name, spec.schema)
        return Optional.empty()
    end

    -- XXX: this is for compatibilty with the PackageSpec structure
    spec.desc = spec.description
    return Optional.of(spec)
end

---@param buffer table<string, Package>
---@param spec RegistryPackageSpec
M.hydrate_package = _.curryN(function(buffer, spec)
    -- hydrate Pkg.Lang index
    _.each(function(lang)
        local _ = Pkg.Lang[lang]
    end, spec.languages)

    local pkg = buffer[spec.name]
    if pkg then
        -- Apply spec to the existing Package instance. This is important as to not have lingering package instances.
        pkg.spec = spec
        return pkg
    end
    return Pkg.new(spec)
end, 2)

return M
