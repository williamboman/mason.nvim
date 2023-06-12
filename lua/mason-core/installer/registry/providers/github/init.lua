local Result = require "mason-core.result"

local M = {}

---@param source GitHubReleaseSource | GitHubBuildSource
---@param purl Purl
---@param opts PackageInstallOpts
function M.parse(source, purl, opts)
    if source.asset then
        source = source --[[@as GitHubReleaseSource]]
        return require("mason-core.installer.registry.providers.github.release").parse(source, purl, opts)
    elseif source.build then
        source = source --[[@as GitHubBuildSource]]
        return require("mason-core.installer.registry.providers.github.build").parse(source, purl, opts)
    else
        return Result.failure "Unknown source type."
    end
end

---@async
---@param ctx InstallContext
---@param source ParsedGitHubReleaseSource | ParsedGitHubBuildSource
function M.install(ctx, source, purl)
    if source.asset then
        source = source--[[@as ParsedGitHubReleaseSource]]
        return require("mason-core.installer.registry.providers.github.release").install(ctx, source)
    elseif source.build then
        source = source--[[@as ParsedGitHubBuildSource]]
        return require("mason-core.installer.registry.providers.github.build").install(ctx, source)
    else
        return Result.failure "Unknown source type."
    end
end

---@async
---@param purl Purl
---@param source GitHubReleaseSource | GitHubBuildSource
function M.get_versions(purl, source)
    if source.asset then
        return require("mason-core.installer.registry.providers.github.release").get_versions(purl)
    elseif source.build then
        -- We can't yet reliably determine the true source (release, tag, commit, etc.) for "build" sources.
        return Result.failure "Unimplemented."
    else
        return Result.failure "Unknown source type."
    end
end

return M
