local _ = require "mason-core.functional"
local log = require "mason-core.log"
local fetch = require "mason-core.fetch"
local spawn = require "mason-core.spawn"

local M = {}

---@alias GitHubReleaseAsset {url: string, id: integer, name: string, browser_download_url: string, created_at: string, updated_at: string, size: integer, download_count: integer}
---@alias GitHubRelease {tag_name: string, prerelease: boolean, draft: boolean, assets:GitHubReleaseAsset[]}
---@alias GitHubTag {name: string}

---@param path string
---@return Result # JSON decoded response.
local function api_call(path)
    return spawn
        .gh({ "api", path })
        :map(_.prop "stdout")
        :recover_catching(function()
            return fetch(("https://api.github.com/%s"):format(path)):get_or_throw()
        end)
        :map_catching(vim.json.decode)
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<GitHubRelease[]>
function M.fetch_releases(repo)
    log.fmt_trace("Fetching GitHub releases for repo=%s", repo)
    local path = ("repos/%s/releases"):format(repo)
    return api_call(path):map_err(function()
        return ("Failed to fetch releases for GitHub repository %s."):format(repo)
    end)
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@param tag_name string The tag_name of the release to fetch.
function M.fetch_release(repo, tag_name)
    log.fmt_trace("Fetching GitHub release for repo=%s, tag_name=%s", repo, tag_name)
    local path = ("repos/%s/releases/tags/%s"):format(repo, tag_name)
    return api_call(path):map_err(function()
        return ("Failed to fetch release %q for GitHub repository %s."):format(tag_name, repo)
    end)
end

---@param opts {include_prerelease: boolean, tag_name_pattern: string}
function M.release_predicate(opts)
    local is_not_draft = _.prop_eq("draft", false)
    local is_not_prerelease = _.prop_eq("prerelease", false)
    local tag_name_matches = _.prop_satisfies(_.matches(opts.tag_name_pattern), "tag_name")

    return _.all_pass {
        _.if_else(_.always(opts.include_prerelease), _.T, is_not_prerelease),
        _.if_else(_.always(opts.tag_name_pattern), tag_name_matches, _.T),
        is_not_draft,
    }
end

---@alias FetchLatestGithubReleaseOpts {tag_name_pattern:string?, include_prerelease: boolean}

---@async
---@param repo string The GitHub repo ("username/repo").
---@param opts FetchLatestGithubReleaseOpts?
---@return Result # Result<GitHubRelease>
function M.fetch_latest_release(repo, opts)
    opts = opts or {
        tag_name_pattern = nil,
        include_prerelease = false,
    }
    return M.fetch_releases(repo):map_catching(
        ---@param releases GitHubRelease[]
        function(releases)
            local is_stable_release = M.release_predicate(opts)
            ---@type GitHubRelease|nil
            local latest_release = _.find_first(is_stable_release, releases)

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
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<GitHubTag[]>
function M.fetch_tags(repo)
    local path = ("repos/%s/tags"):format(repo)
    return api_call(path):map_err(function()
        return ("Failed to fetch tags for GitHub repository %s."):format(repo)
    end)
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<string> The latest tag name.
function M.fetch_latest_tag(repo)
    -- https://github.com/williamboman/vercel-github-api-latest-tag-proxy
    return fetch(("https://latest-github-tag.redwill.se/api/repo/%s/latest-tag"):format(repo))
        :map_catching(vim.json.decode)
        :map(_.prop "tag")
end

---@alias GitHubRateLimit {limit: integer, remaining: integer, reset: integer, used: integer}
---@alias GitHubRateLimitResponse {resources: { core: GitHubRateLimit }}

---@async
--@return Result @of GitHubRateLimitResponse
function M.fetch_rate_limit()
    return api_call "rate_limit"
end

return M
