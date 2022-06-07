local installer = require "nvim-lsp-installer.core.installer"
local std = require "nvim-lsp-installer.core.managers.std"
local client = require "nvim-lsp-installer.core.managers.github.client"
local platform = require "nvim-lsp-installer.core.platform"
local Result = require "nvim-lsp-installer.core.result"
local _ = require "nvim-lsp-installer.core.functional"
local settings = require "nvim-lsp-installer.settings"

local M = {}

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
---@param opts {repo: string, version: Optional|nil, asset_file: string|fun(release: string):string}
function M.release_file(opts)
    local ctx = installer.context()
    local release = _.coalesce(opts.version, ctx.requested_version):or_else_get(function()
        return client.fetch_latest_release(opts.repo)
            :map(_.prop "tag_name")
            :get_or_throw "Failed to fetch latest release from GitHub API. Refer to :h nvim-lsp-installer-errors-github-api for more information."
    end)
    ---@type string
    local asset_file
    if type(opts.asset_file) == "function" then
        asset_file = opts.asset_file(release)
    else
        asset_file = opts.asset_file
    end
    if not asset_file then
        error(
            (
                "Could not find which release file to download.\nMost likely the current operating system, architecture (%s), or libc (%s) is not supported."
            ):format(platform.arch, platform.get_libc()),
            0
        )
    end
    local download_url = settings.current.github.download_url_template:format(opts.repo, release, asset_file)
    return {
        release = release,
        download_url = download_url,
        asset_file = asset_file,
        with_receipt = with_release_file_receipt(opts.repo, download_url, release),
    }
end

---@async
---@param opts {repo: string, version: Optional|nil}
function M.tag(opts)
    local ctx = installer.context()
    local tag = _.coalesce(opts.version, ctx.requested_version):or_else_get(function()
        return client.fetch_latest_tag(opts.repo)
            :map(_.prop "name")
            :get_or_throw "Failed to fetch latest tag from GitHub API."
    end)

    return {
        tag = tag,
        with_receipt = with_tag_receipt(opts.repo, tag),
    }
end

---@param filename string
---@param processor async fun()
local function release_file_processor(filename, processor)
    ---@async
    ---@param opts {repo: string, asset_file: string|fun(release: string):string}
    return function(opts)
        local release_file_source = M.release_file(opts)
        std.download_file(release_file_source.download_url, filename)
        processor(release_file_source)
        return release_file_source
    end
end

M.unzip_release_file = release_file_processor("archive.zip", function()
    std.unzip("archive.zip", ".")
end)

M.untarxz_release_file = release_file_processor("archive.tar.xz", function()
    std.untarxz "archive.tar.xz"
end)

M.untargz_release_file = release_file_processor("archive.tar.gz", function()
    std.untar "archive.tar.gz"
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
---@param receipt InstallReceipt
function M.check_outdated_primary_package_release(receipt)
    local source = receipt.primary_source
    if source.type ~= "github_release" and source.type ~= "github_release_file" then
        return Result.failure "Receipt does not have a primary source of type (github_release|github_release_file)."
    end
    return client.fetch_latest_release(source.repo, { tag_name_pattern = source.tag_name_pattern }):map_catching(
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
---@param receipt InstallReceipt
function M.check_outdated_primary_package_tag(receipt)
    local source = receipt.primary_source
    if source.type ~= "github_tag" then
        return Result.failure "Receipt does not have a primary source of type github_tag."
    end
    return client.fetch_latest_tag(source.repo):map_catching(
        ---@param latest_tag GitHubTag
        function(latest_tag)
            if source.tag ~= latest_tag.name then
                return {
                    name = source.repo,
                    current_version = source.tag,
                    latest_version = latest_tag.name,
                }
            end
            error "Primary package is not outdated."
        end
    )
end

return M
