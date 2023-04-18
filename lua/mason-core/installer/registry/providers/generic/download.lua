local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local expr = require "mason-core.installer.registry.expr"
local util = require "mason-core.installer.registry.util"

local M = {}

---@class GenericDownload
---@field target (Platform | Platform[])?
---@field files table<string, string>

---@class GenericDownloadSource : RegistryPackageSource
---@field download GenericDownload | GenericDownload[]

---@param source GenericDownloadSource
---@param purl Purl
---@param opts PackageInstallOpts
function M.parse(source, purl, opts)
    return Result.try(function(try)
        local download = try(util.coalesce_by_target(source.download, opts):ok_or "PLATFORM_UNSUPPORTED")

        local expr_ctx = { version = purl.version }
        ---@type { files: table<string, string> }
        local interpolated_download = try(expr.tbl_interpolate(download, expr_ctx))

        ---@class ParsedGenericDownloadSource : ParsedPackageSource
        local parsed_source = {
            download = interpolated_download,
        }
        return parsed_source
    end)
end

---@async
---@param ctx InstallContext
---@param source ParsedGenericDownloadSource
function M.install(ctx, source)
    local std = require "mason-core.installer.managers.std"
    return Result.try(function(try)
        for out_file, url in pairs(source.download.files) do
            try(std.download_file(url, out_file))
            try(std.unpack(out_file))
        end
    end)
end

return M
