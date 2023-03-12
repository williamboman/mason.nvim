local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local util = require "mason-core.installer.registry.util"

local M = {}

---@class CargoSource : RegistryPackageSource
---@field supported_platforms? string[]

---@param source CargoSource
---@param purl Purl
function M.parse(source, purl)
    return Result.try(function(try)
        if source.supported_platforms then
            try(util.ensure_valid_platform(source.supported_platforms))
        end

        local repository_url = _.path({ "qualifiers", "repository_url" }, purl)

        local git
        if repository_url then
            git = {
                url = repository_url,
                rev = _.path({ "qualifiers", "rev" }, purl) == "true",
            }
        end

        ---@type string?
        local features = _.path({ "qualifiers", "features" }, purl)
        local locked = _.path({ "qualifiers", "locked" }, purl)

        ---@class ParsedCargoSource : ParsedPackageSource
        local parsed_source = {
            crate = purl.name,
            version = purl.version,
            features = features,
            locked = locked ~= "false",
            git = git,
        }
        return parsed_source
    end)
end

---@async
---@param ctx InstallContext
---@param source ParsedCargoSource
function M.install(ctx, source)
    local cargo = require "mason-core.installer.managers.cargo"
    local providers = require "mason-core.providers"

    return Result.try(function(try)
        try(util.ensure_valid_version(function()
            return providers.crates.get_all_versions(source.crate)
        end))

        try(cargo.install(source.crate, source.version, {
            git = source.git,
            features = source.features,
            locked = source.locked,
        }))
    end)
end

return M
