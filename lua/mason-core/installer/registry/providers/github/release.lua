local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local expr = require "mason-core.installer.registry.expr"
local providers = require "mason-core.providers"
local settings = require "mason.settings"
local util = require "mason-core.installer.registry.util"

---@class GitHubReleaseAsset
---@field target? Platform | Platform[]
---@field file string | string[]

---@class GitHubReleaseSource : RegistryPackageSource
---@field asset GitHubReleaseAsset | GitHubReleaseAsset[]

local M = {}

---@param source GitHubReleaseSource
---@param purl Purl
---@param opts PackageInstallOpts
function M.parse(source, purl, opts)
    return Result.try(function(try)
        local asset = try(util.coalesce_by_target(source.asset, opts):ok_or "PLATFORM_UNSUPPORTED")

        local expr_ctx = { version = purl.version }

        ---@type { out_file: string, download_url: string }[]
        local downloads = {}

        local interpolated_asset = try(expr.tbl_interpolate(asset, expr_ctx))

        ---@param file string
        ---@return Result # Result<{ source_file: string, out_file: string }>
        local function parse_asset_file(file)
            return Result.try(function(try)
                local asset_file_components = _.split(":", file)
                local source_file = try(expr.interpolate(_.head(asset_file_components), expr_ctx))
                local out_file = try(expr.interpolate(_.last(asset_file_components), expr_ctx))

                if _.matches("/$", out_file) then
                    -- out_file is a dir expression (e.g. "libexec/")
                    out_file = out_file .. source_file
                end

                return {
                    source_file = source_file,
                    out_file = out_file,
                }
            end)
        end

        local get_downloads = _.map(function(asset_file)
            return {
                out_file = asset_file.out_file,
                download_url = settings.current.github.download_url_template:format(
                    ("%s/%s"):format(purl.namespace, purl.name),
                    purl.version,
                    asset_file.source_file
                ),
            }
        end)

        if type(asset.file) == "string" then
            local parsed_asset_file = try(parse_asset_file(asset.file))
            downloads = get_downloads { parsed_asset_file }
            interpolated_asset.file = parsed_asset_file.out_file
        else
            local parsed_asset_files = {}
            for _, file in ipairs(asset.file) do
                table.insert(parsed_asset_files, try(parse_asset_file(file)))
            end
            downloads = get_downloads(parsed_asset_files)
            interpolated_asset.file = _.map(_.prop "out_file", parsed_asset_files)
        end

        ---@class ParsedGitHubReleaseSource : ParsedPackageSource
        local parsed_source = {
            repo = ("%s/%s"):format(purl.namespace, purl.name),
            asset = interpolated_asset,
            downloads = downloads,
        }
        return parsed_source
    end)
end

---@async
---@param ctx InstallContext
---@param source ParsedGitHubReleaseSource
function M.install(ctx, source)
    local std = require "mason-core.installer.managers.std"

    return Result.try(function(try)
        for __, download in ipairs(source.downloads) do
            a.scheduler()
            local out_dir = vim.fn.fnamemodify(download.out_file, ":h")
            local out_file = vim.fn.fnamemodify(download.out_file, ":t")
            if out_dir ~= "." then
                try(Result.pcall(function()
                    ctx.fs:mkdirp(out_dir)
                end))
            end
            try(ctx:chdir(out_dir, function()
                return Result.try(function(try)
                    try(std.download_file(download.download_url, out_file))
                    try(std.unpack(out_file))
                end)
            end))
        end
    end)
end

---@async
---@param purl Purl
function M.get_versions(purl)
    return providers.github.get_all_release_versions(("%s/%s"):format(purl.namespace, purl.name))
end

return M
