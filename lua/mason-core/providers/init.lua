local settings = require "mason.settings"
local log = require "mason-core.log"
local Result = require "mason-core.result"

---@alias GitHubReleaseAsset {url: string, id: integer, name: string, browser_download_url: string, created_at: string, updated_at: string, size: integer, download_count: integer}
---@alias GitHubRelease { tag_name: string, prerelease: boolean, draft: boolean, assets:GitHubReleaseAsset[] }
---@alias GitHubTag { name: string }

---@class GitHubProvider
---@field get_latest_release? async fun(repo: string, opts?: { include_prerelease?: boolean }): Result # Result<GitHubRelease>
---@field get_all_release_versions? async fun(repo: string): Result # Result<string[]>
---@field get_latest_tag? async fun(repo: string): Result # Result<GitHubTag>
---@field get_all_tags? async fun(repo: string): Result # Result<string[]>

---@alias NpmPackage { name: string, version: string }

---@class NpmProvider
---@field get_latest_version? async fun(pkg: string): Result # Result<NpmPackage>
---@field get_all_versions? async fun(pkg: string): Result # Result<string[]>

---@class Provider
---@field github? GitHubProvider
---@field npm? NpmProvider

local function lazy_require(module)
    return setmetatable({}, {
        __index = function(_, k)
            return require(module)[k]
        end,
    })
end

---@type table<string, Provider>
local providers = {
    ["mason-registry-api"] = lazy_require "mason-core.providers.registry-api",
    ["client-only"] = lazy_require "mason-core.providers.client-only",
}

local function service_mt(service)
    return setmetatable({}, {
        __index = function(_, method)
            return function(...)
                if #settings.current.providers < 1 then
                    log.error "No providers configured."
                    return Result.failure "1 or more providers are required."
                end
                for _, provider_name in ipairs(settings.current.providers) do
                    local provider = providers[provider_name]
                    if provider then
                        local impl = provider[service] and provider[service][method]
                        if impl then
                            ---@type boolean, Result
                            local ok, result = pcall(impl, ...)
                            if ok and result:is_success() then
                                return result
                            else
                                log.fmt_error("Provider %s %s failed: %s", service, method, result:err_or_nil())
                            end
                        end
                    else
                        log.fmt_error("Provider %s is not registered.", provider_name)
                    end
                end
                local err = ("No provider implementation found for %s.%s"):format(service, method)
                log.error(err)
                return Result.failure(err)
            end
        end,
    })
end

return {
    ---@type Provider
    service = setmetatable({}, {
        __index = function(tbl, service)
            tbl[service] = service_mt(service)
            return tbl[service]
        end,
    }),
    ---@param key string
    ---@param provider Provider
    register = function(key, provider)
        providers[key] = provider
    end,
}
