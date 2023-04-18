local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local build = require "mason-core.installer.managers.build"
local expr = require "mason-core.installer.registry.expr"
local util = require "mason-core.installer.registry.util"

local M = {}

---@class GitHubBuildSource : RegistryPackageSource
---@field build BuildInstruction | BuildInstruction[]

---@param source GitHubBuildSource
---@param purl Purl
---@param opts PackageInstallOpts
function M.parse(source, purl, opts)
    return Result.try(function(try)
        ---@type BuildInstruction
        local build_instruction = try(util.coalesce_by_target(source.build, opts):ok_or "PLATFORM_UNSUPPORTED")

        local expr_ctx = { version = purl.version }

        -- TODO: In a few releases of the core registry, r-languageserver reads $MASON_VERSION directly. Remove this
        -- some time in the future.
        local default_env = {
            MASON_VERSION = purl.version,
        }
        build_instruction.env =
            vim.tbl_extend("force", default_env, try(expr.tbl_interpolate(build_instruction.env or {}, expr_ctx)))

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
function M.install(ctx, source)
    local std = require "mason-core.installer.managers.std"
    return Result.try(function(try)
        try(std.clone(source.repo, { rev = source.rev }))
        try(build.run(source.build))
    end)
end

return M
