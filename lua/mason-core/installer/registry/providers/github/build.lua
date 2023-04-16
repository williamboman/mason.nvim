local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local async_uv = require "mason-core.async.uv"
local platform = require "mason-core.platform"
local util = require "mason-core.installer.registry.util"

---@class GitHubBuildInstruction
---@field target? Platform | Platform[]
---@field run string

---@class GitHubBuildSource : RegistryPackageSource
---@field build GitHubBuildInstruction | GitHubBuildInstruction[]

local M = {}

---@param source GitHubBuildSource
---@param purl Purl
---@param opts PackageInstallOpts
function M.parse(source, purl, opts)
    return Result.try(function(try)
        ---@type { run: string }
        local build_instruction = try(util.coalesce_by_target(source.build, opts):ok_or "PLATFORM_UNSUPPORTED")

        ---@class ParsedGitHubBuildSource : ParsedPackageSource
        local parsed_source = {
            build = build_instruction,
            repo = ("https://github.com/%s/%s.git"):format(purl.namespace, purl.name),
            rev = purl.version,
        }
        return parsed_source
    end)
end

---@async
---@param ctx InstallContext
---@param source ParsedGitHubBuildSource
---@param purl Purl
function M.install(ctx, source, purl)
    local std = require "mason-core.installer.managers.std"
    return Result.try(function(try)
        try(std.clone(source.repo, { rev = source.rev }))
        try(platform.when {
            unix = function()
                return ctx.spawn.bash {
                    on_spawn = a.scope(function(_, stdio)
                        local stdin = stdio[1]
                        async_uv.write(stdin, "set -euxo pipefail;\n")
                        async_uv.write(stdin, source.build.run)
                        async_uv.shutdown(stdin)
                        async_uv.close(stdin)
                    end),
                    env = {
                        MASON_VERSION = purl.version,
                    },
                }
            end,
            win = function()
                local powershell = require "mason-core.managers.powershell"
                return powershell.command(source.build.run, {
                    env = {
                        MASON_VERSION = purl.version,
                    },
                }, ctx.spawn)
            end,
        })
    end)
end

return M
