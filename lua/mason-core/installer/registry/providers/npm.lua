local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local util = require "mason-core.installer.registry.util"

---@param purl Purl
local function purl_to_npm(purl)
    if purl.namespace then
        return ("%s/%s"):format(purl.namespace, purl.name)
    else
        return purl.name
    end
end

local M = {}

---@class NpmSource : RegistryPackageSource
---@field extra_packages? string[]

---@param source NpmSource
---@param purl Purl
function M.parse(source, purl)
    ---@class ParsedNpmSource : ParsedPackageSource
    local parsed_source = {
        package = purl_to_npm(purl),
        version = purl.version,
        extra_packages = source.extra_packages,
    }

    return Result.success(parsed_source)
end

---@async
---@param ctx InstallContext
---@param source ParsedNpmSource
function M.install(ctx, source)
    local npm = require "mason-core.installer.managers.npm"
    local providers = require "mason-core.providers"

    return Result.try(function(try)
        try(util.ensure_valid_version(function()
            return providers.npm.get_all_versions(source.package)
        end))

        try(npm.init())
        try(npm.install(source.package, source.version, {
            extra_packages = source.extra_packages,
        }))
    end)
end

return M
