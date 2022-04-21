local Data = require "nvim-lsp-installer.data"
local log = require "nvim-lsp-installer.log"
local fetch = require "nvim-lsp-installer.core.fetch"
local spawn = require "nvim-lsp-installer.core.spawn"

local list_find_first = Data.list_find_first

local M = {}

---@alias GitHubReleaseAsset {url: string, id: integer, name: string, browser_download_url: string, created_at: string, updated_at: string, size: integer, download_count: integer}
---@alias GitHubRelease {tag_name: string, prerelease: boolean, draft: boolean, assets:GitHubReleaseAsset[]}
---@alias GitHubTag {name: string}

---@param path string
---@return Result @JSON decoded response.
local function api_call(path)
    return spawn.gh({ "api", path })
        :map(function(result)
            return result.stdout
        end)
        :recover_catching(function()
            return fetch(("https://api.github.com/%s"):format(path)):get_or_throw()
        end)
        :map_catching(vim.json.decode)
end

---@async
---@param repo string @The GitHub repo ("username/repo").
function M.fetch_releases(repo)
    log.fmt_trace("Fetching GitHub releases for repo=%s", repo)
    local path = ("repos/%s/releases"):format(repo)
    return api_call(path):map_err(function()
        return ("Failed to fetch releases for GitHub repository %s."):format(repo)
    end)
end

---@async
---@param repo string @The GitHub repo ("username/repo").
---@param tag_name string @The tag_name of the release to fetch.
function M.fetch_release(repo, tag_name)
    log.fmt_trace("Fetching GitHub release for repo=%s, tag_name=%s", repo, tag_name)
    local path = ("repos/%s/releases/tags/%s"):format(repo, tag_name)
    return api_call(path):map_err(function()
        return ("Failed to fetch release %q for GitHub repository %s."):format(tag_name, repo)
    end)
end

---@alias FetchLatestGithubReleaseOpts {tag_name_pattern:string}

---@async
---@param repo string @The GitHub repo ("username/repo").
---@param opts FetchLatestGithubReleaseOpts|nil
---@return Result @of GitHubRelease
function M.fetch_latest_release(repo, opts)
    opts = opts or {}
    return M.fetch_releases(repo):map_catching(
        ---@param releases GitHubRelease[]
        function(releases)
            ---@type GitHubRelease|nil
            local latest_release = list_find_first(
                releases,
                ---@param release GitHubRelease
                function(release)
                    local is_stable_release = not release.prerelease and not release.draft
                    if opts.tag_name_pattern then
                        return is_stable_release and release.tag_name:match(opts.tag_name_pattern)
                    end
                    return is_stable_release
                end
            )

            if not latest_release then
                log.fmt_info("Failed to find latest release. repo=%s, opts=%s", repo, opts)
                error "Failed to find latest release."
            end

            log.fmt_debug("Resolved latest version repo=%s, tag_name=%s", repo, latest_release.tag_name)
            return latest_release
        end
    )
end

---@async
---@param repo string @The GitHub repo ("username/repo").
---@return Result @of [GitHubTag[]]
function M.fetch_tags(repo)
    local path = ("repos/%s/tags"):format(repo)
    return api_call(path):map_err(function()
        return ("Failed to fetch tags for GitHub repository %s."):format(repo)
    end)
end

---@async
---@param repo string @The GitHub repo ("username/repo").
---@return Result @of [GitHubTag]
function M.fetch_latest_tag(repo)
    return M.fetch_tags(repo):map_catching(function(tags)
        if vim.tbl_count(tags) == 0 then
            error "No tags found."
        end
        return tags[1]
    end)
end

return M
