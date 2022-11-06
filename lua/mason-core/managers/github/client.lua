local _ = require "mason-core.functional"
local log = require "mason-core.log"
local fetch = require "mason-core.fetch"
local spawn = require "mason-core.spawn"
local providers = require "mason-core.providers"

local M = {}

---@alias GitHubCommit {sha: string}

local stringify_params = _.compose(_.join "&", _.map(_.join "="), _.sort_by(_.head), _.to_pairs)

---@param path string
---@param opts { params: table<string, any>? }?
---@return Result # JSON decoded response.
local function gh_api_call(path, opts)
    if opts and opts.params then
        local params = stringify_params(opts.params)
        path = ("%s?%s"):format(path, params)
    end
    return spawn
        .gh({ "api", path, env = { CLICOLOR_FORCE = 0 } })
        :map(_.prop "stdout")
        :recover_catching(function()
            return fetch(("https://api.github.com/%s"):format(path), {
                headers = {
                    Accept = "application/vnd.github.v3+json; q=1.0, application/json; q=0.8",
                },
            }):get_or_throw()
        end)
        :map_catching(vim.json.decode)
end

M.api_call = gh_api_call

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<GitHubRelease[]>
function M.fetch_releases(repo)
    log.fmt_trace("Fetching GitHub releases for repo=%s", repo)
    local path = ("repos/%s/releases"):format(repo)
    return gh_api_call(path):map_err(function()
        return ("Failed to fetch releases for GitHub repository %s."):format(repo)
    end)
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@param tag_name string The tag_name of the release to fetch.
function M.fetch_release(repo, tag_name)
    log.fmt_trace("Fetching GitHub release for repo=%s, tag_name=%s", repo, tag_name)
    local path = ("repos/%s/releases/tags/%s"):format(repo, tag_name)
    return gh_api_call(path):map_err(function()
        return ("Failed to fetch release %q for GitHub repository %s."):format(tag_name, repo)
    end)
end

---@alias FetchLatestGithubReleaseOpts {include_prerelease: boolean}

---@async
---@param repo string The GitHub repo ("username/repo").
---@param opts FetchLatestGithubReleaseOpts?
---@return Result # Result<GitHubRelease>
function M.fetch_latest_release(repo, opts)
    opts = opts or { include_prerelease = false }
    return providers.github.get_latest_release(repo, { include_prerelease = opts.include_prerelease })
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<GitHubTag[]>
function M.fetch_tags(repo)
    local path = ("repos/%s/tags"):format(repo)
    return gh_api_call(path):map_err(function()
        return ("Failed to fetch tags for GitHub repository %s."):format(repo)
    end)
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<string> The latest tag name.
function M.fetch_latest_tag(repo)
    return providers.github.get_latest_tag(repo):map(_.prop "tag")
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@param opts { page: integer?, per_page: integer? }?
---@return Result # Result<GitHubCommit[]>
function M.fetch_commits(repo, opts)
    local path = ("repos/%s/commits"):format(repo)
    return gh_api_call(path, {
        params = {
            page = opts and opts.page or 1,
            per_page = opts and opts.per_page or 30,
        },
    }):map_err(function()
        return ("Failed to fetch commits for GitHub repository %s."):format(repo)
    end)
end

---@alias GitHubRateLimit {limit: integer, remaining: integer, reset: integer, used: integer}
---@alias GitHubRateLimitResponse {resources: { core: GitHubRateLimit }}

---@async
--@return Result @of GitHubRateLimitResponse
function M.fetch_rate_limit()
    return gh_api_call "rate_limit"
end

return M
