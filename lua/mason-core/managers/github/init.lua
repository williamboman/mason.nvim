local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local platform = require "mason-core.platform"
local providers = require "mason-core.providers"
local settings = require "mason.settings"
local std = require "mason-core.managers.std"

local M = {}

---@class InstallReceiptGitHubReleaseFileSource
---@field type '"github_release_file"'
---@field repo string
---@field file string
---@field release string

---@param repo string
---@param asset_file string
---@param release string
local function with_release_file_receipt(repo, asset_file, release)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source {
            type = "github_release_file",
            repo = repo,
            file = asset_file,
            release = release,
        }
    end
end

---@class InstallReceiptGitHubTagSource
---@field type '"github_tag"'
---@field repo string
---@field tag string

---@param repo string
---@param tag string
local function with_tag_receipt(repo, tag)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source {
            type = "github_tag",
            repo = repo,
            tag = tag,
        }
    end
end

---@async
---@param opts {repo: string, version: Optional?}
function M.release_version(opts)
    local ctx = installer.context()
    ---@type string
    local release = _.coalesce(opts.version, ctx.requested_version):or_else_get(function()
        return providers.github
            .get_latest_release(opts.repo)
            :map(_.prop "tag_name")
            :get_or_throw "Failed to fetch latest release from GitHub API. Refer to :h mason-provider-errors for more information."
    end)

    return {
        with_receipt = function()
            ctx.receipt:with_primary_source {
                type = "github_release",
                repo = opts.repo,
                release = release,
            }
        end,
        release = release,
    }
end

---@async
---@param opts {repo: string, version: Optional?, asset_file: string|fun(release: string):string}
function M.release_file(opts)
    local source = M.release_version(opts)
    ---@type string
    local asset_file
    if type(opts.asset_file) == "function" then
        asset_file = opts.asset_file(source.release)
    elseif type(opts.asset_file) == "string" then
        asset_file = opts.asset_file --[[@as string]]
    end
    if not asset_file then
        error(
            (
                "Could not find which release file to download.\n"
                .. "Most likely the current operating system or architecture is not supported (%s_%s)."
            ):format(platform.sysname, platform.arch),
            0
        )
    end
    local download_url = settings.current.github.download_url_template:format(opts.repo, source.release, asset_file)
    return {
        release = source.release,
        download_url = download_url,
        asset_file = asset_file,
        with_receipt = with_release_file_receipt(opts.repo, download_url, source.release),
    }
end

---@async
---@param opts {repo: string, version: Optional?}
function M.tag(opts)
    local ctx = installer.context()
    local tag = _.coalesce(opts.version, ctx.requested_version):or_else_get(function()
        return providers.github
            .get_latest_tag(opts.repo)
            :map(_.prop "tag")
            :get_or_throw "Failed to fetch latest tag from GitHub API."
    end)

    return {
        tag = tag,
        with_receipt = with_tag_receipt(opts.repo, tag),
    }
end

---@param filename string
---@param processor async fun(opts: table)
local function release_file_processor(filename, processor)
    ---@async
    ---@param opts {repo: string, version: Optional|nil, asset_file: string|fun(release: string):string}
    return function(opts)
        local release_file_source = M.release_file(opts)
        std.download_file(release_file_source.download_url, filename)
        processor(opts)
        return release_file_source
    end
end

M.unzip_release_file = release_file_processor("archive.zip", function()
    std.unzip("archive.zip", ".")
end)

M.untarzst_release_file = release_file_processor("archive.tar.zst", function(opts)
    std.untarzst("archive.tar.zst", { strip_components = opts.strip_components })
end)

M.untarxz_release_file = release_file_processor("archive.tar.xz", function(opts)
    std.untarxz("archive.tar.xz", { strip_components = opts.strip_components })
end)

M.untargz_release_file = release_file_processor("archive.tar.gz", function(opts)
    std.untar("archive.tar.gz", { strip_components = opts.strip_components })
end)

---@async
---@param opts {repo: string, out_file:string, asset_file: string|fun(release: string):string}
function M.download_release_file(opts)
    local release_file_source = M.release_file(opts)
    std.download_file(release_file_source.download_url, assert(opts.out_file, "out_file is required"))
    return release_file_source
end

---@async
---@param opts {repo: string, out_file:string, asset_file: string|fun(release: string):string}
function M.gunzip_release_file(opts)
    local release_file_source = M.release_file(opts)
    local gzipped_file = ("%s.gz"):format(assert(opts.out_file, "out_file must be specified"))
    std.download_file(release_file_source.download_url, gzipped_file)
    std.gunzip(gzipped_file)
    return release_file_source
end

---@async
---@param receipt InstallReceipt<InstallReceiptGitHubReleaseFileSource>
function M.check_outdated_primary_package_release(receipt)
    local source = receipt.primary_source
    if source.type ~= "github_release" and source.type ~= "github_release_file" then
        return Result.failure "Receipt does not have a primary source of type (github_release|github_release_file)."
    end
    return providers.github.get_latest_release(source.repo):map_catching(
        ---@param latest_release GitHubRelease
        function(latest_release)
            if source.release ~= latest_release.tag_name then
                return {
                    name = source.repo,
                    current_version = source.release,
                    latest_version = latest_release.tag_name,
                }
            end
            error "Primary package is not outdated."
        end
    )
end

---@async
---@param receipt InstallReceipt<InstallReceiptGitHubTagSource>
function M.check_outdated_primary_package_tag(receipt)
    local source = receipt.primary_source
    if source.type ~= "github_tag" then
        return Result.failure "Receipt does not have a primary source of type github_tag."
    end
    return providers.github.get_latest_tag(source.repo):map(_.prop "tag"):map_catching(function(latest_tag)
        if source.tag ~= latest_tag then
            return {
                name = source.repo,
                current_version = source.tag,
                latest_version = latest_tag,
            }
        end
        error "Primary package is not outdated."
    end)
end

return M
