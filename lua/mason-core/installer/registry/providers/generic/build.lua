local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local build = require "mason-core.installer.managers.build"
local expr = require "mason-core.installer.registry.expr"
local util = require "mason-core.installer.registry.util"

local M = {}

---@class GenericBuildSource : RegistryPackageSource
---@field build BuildInstruction | BuildInstruction[]

---@param source GenericBuildSource
---@param purl Purl
---@param opts PackageInstallOpts
function M.parse(source, purl, opts)
    return Result.try(function(try)
        ---@type BuildInstruction
        local build_instruction = try(util.coalesce_by_target(source.build, opts):ok_or "PLATFORM_UNSUPPORTED")

        if build_instruction.env then
            local expr_ctx = { version = purl.version, target = build_instruction.target }
            build_instruction.env = try(expr.tbl_interpolate(build_instruction.env, expr_ctx))
        end

        ---@class ParsedGenericBuildSource : ParsedPackageSource
        local parsed_source = {
            build = build_instruction,
        }
        return parsed_source
    end)
end

---@async
---@param ctx InstallContext
---@param source ParsedGenericBuildSource
function M.install(ctx, source)
    return build.run(source.build)
end

return M
