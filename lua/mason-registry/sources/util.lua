local Optional = require "mason-core.optional"
local Package = require "mason-core.package"
local _ = require "mason-core.functional"
local compiler = require "mason-core.installer.compiler"
local log = require "mason-core.log"

local M = {}

---@param spec RegistryPackageSpec
function M.map_registry_spec(spec)
    spec.schema = spec.schema or "registry+v1"

    if not compiler.SCHEMA_CAP[spec.schema] then
        log.fmt_debug("Excluding package=%s with unsupported schema_version=%s", spec.name, spec.schema)
        return Optional.empty()
    end

    return Optional.of(spec)
end

---@param buffer table<string, Package>
---@param spec RegistryPackageSpec
M.hydrate_package = _.curryN(function(buffer, spec)
    -- hydrate Pkg.Lang/License index
    _.each(function(lang)
        local _ = Package.Lang[lang]
    end, spec.languages)
    _.each(function(lang)
        local _ = Package.License[lang]
    end, spec.licenses)

    local pkg = buffer[spec.name]
    if pkg then
        -- Apply spec to the existing Package instances. This is important as to not have lingering package instances.
        pkg.spec = spec
        return pkg
    end
    return Package:new(spec)
end, 2)

return M
