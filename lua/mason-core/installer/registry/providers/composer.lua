local Result = require "mason-core.result"
local util = require "mason-core.installer.registry.util"

local M = {}

---@param source RegistryPackageSource
---@param purl Purl
function M.parse(source, purl)
    ---@class ParsedComposerSource : ParsedPackageSource
    local parsed_source = {
        package = ("%s/%s"):format(purl.namespace, purl.name),
        version = purl.version,
    }

    return Result.success(parsed_source)
end

---@async
---@param ctx InstallContext
---@param source ParsedComposerSource
function M.install(ctx, source)
    local composer = require "mason-core.installer.managers.composer"
    local providers = require "mason-core.providers"

    return Result.try(function(try)
        try(util.ensure_valid_version(function()
            return providers.packagist.get_all_versions(source.package)
        end))

        try(composer.install(source.package, source.version))
    end)
end

return M
