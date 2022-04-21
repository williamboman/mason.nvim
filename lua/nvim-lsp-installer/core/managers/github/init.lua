local installer = require "nvim-lsp-installer.core.installer"
local std = require "nvim-lsp-installer.core.managers.std"
local client = require "nvim-lsp-installer.core.managers.github.client"
local platform = require "nvim-lsp-installer.platform"

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

---@async
---@param opts {repo: string, version: Optional|nil, asset_file: string|fun(release: string):string}
function M.release_file(opts)
    local ctx = installer.context()
    local release = (opts.version or ctx.requested_version):or_else_get(function()
        return client.fetch_latest_release(opts.repo)
            :map(function(release)
                return release.tag_name
            end)
            :get_or_throw "Failed to fetch latest release from GitHub API."
    end)
    ---@type string
    local asset_file = type(opts.asset_file) == "function" and opts.asset_file(release) or opts.asset_file
    if not asset_file then
        error(
            (
                "Could not find which release file to download. Most likely the current operating system, architecture (%s), or libc (%s) is not supported."
            ):format(platform.arch, platform.get_libc())
        )
    end
    local download_url = ("https://github.com/%s/releases/download/%s/%s"):format(opts.repo, release, asset_file)
    return {
        release = release,
        download_url = download_url,
        asset_file = asset_file,
        with_receipt = with_release_file_receipt(opts.repo, download_url, release),
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
function M.gunzip_release_file(opts)
    local release_file_source = M.release_file(opts)
    std.download_file(
        release_file_source.download_url,
        ("%s.gz"):format(assert(opts.out_file, "out_file must be specified"))
    )
    std.gunzip(opts.out_file)
    return release_file_source
end

return M
