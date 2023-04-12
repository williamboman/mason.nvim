local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local async_uv = require "mason-core.async.uv"
local expr = require "mason-core.installer.registry.expr"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local settings = require "mason.settings"
local util = require "mason-core.installer.registry.util"

local build = {
    ---@param source GitHubBuildSource
    ---@param purl Purl
    ---@param opts PackageInstallOpts
    parse = function(source, purl, opts)
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
    end,

    ---@async
    ---@param ctx InstallContext
    ---@param source ParsedGitHubBuildSource
    install = function(ctx, source)
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
                    }
                end,
                win = function()
                    local powershell = require "mason-core.managers.powershell"
                    return powershell.command(source.build.run, {}, ctx.spawn)
                end,
            })
        end)
    end,
}

local release = {
    ---@param source GitHubReleaseSource
    ---@param purl Purl
    ---@param opts PackageInstallOpts
    parse = function(source, purl, opts)
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
    end,

    ---@async
    ---@param ctx InstallContext
    ---@param source ParsedGitHubReleaseSource
    install = function(ctx, source)
        local std = require "mason-core.installer.managers.std"
        local providers = require "mason-core.providers"

        return Result.try(function(try)
            try(util.ensure_valid_version(function()
                return providers.github.get_all_release_versions(source.repo)
            end))

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
    end,
}

local M = {}

---@class GitHubReleaseAsset
---@field target? Platform | Platform[]
---@field file string | string[]

---@class GitHubReleaseSource : RegistryPackageSource
---@field asset GitHubReleaseAsset | GitHubReleaseAsset[]

---@class GitHubBuildInstruction
---@field target? Platform | Platform[]
---@field run string

---@class GitHubBuildSource : RegistryPackageSource
---@field build GitHubBuildInstruction | GitHubBuildInstruction[]

---@param source GitHubReleaseSource | GitHubBuildSource
---@param purl Purl
---@param opts PackageInstallOpts
function M.parse(source, purl, opts)
    if source.asset then
        return release.parse(source --[[@as GitHubReleaseSource]], purl, opts)
    elseif source.build then
        return build.parse(source --[[@as GitHubBuildSource]], purl, opts)
    else
        return Result.failure "Unknown source type."
    end
end

---@async
---@param ctx InstallContext
---@param source ParsedGitHubReleaseSource | ParsedGitHubBuildSource
function M.install(ctx, source)
    if source.asset then
        return release.install(ctx, source)
    elseif source.build then
        return build.install(ctx, source)
    else
        return Result.failure "Unknown source type."
    end
end

return M
