local _ = require "mason-core.functional"
local fetch = require "mason-core.fetch"
local spawn = require "mason-core.spawn"

local M = {}

---@alias GitHubCommit { sha: string }
---@alias GitHubRef { ref: string }

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
        :or_else(function()
            return fetch(("https://api.github.com/%s"):format(path), {
                headers = {
                    Accept = "application/vnd.github.v3+json; q=1.0, application/json; q=0.8",
                },
            })
        end)
        :map_catching(vim.json.decode)
end

M.api_call = gh_api_call

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<GitHubRelease>
function M.fetch_latest_release(repo)
    local path = ("repos/%s/releases/latest"):format(repo)
    return gh_api_call(path)
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<GitHubRelease[]>
function M.fetch_all_releases(repo)
    local path = ("repos/%s/releases"):format(repo)
    return gh_api_call(path)
end

---@async
---@param repo string The GitHub repo ("username/repo").
---@return Result # Result<GitHubRef[]>
function M.fetch_all_tags(repo)
    local path = ("repos/%s/git/matching-refs/tags"):format(repo)
    return gh_api_call(path)
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
---@return Result # Result<GitHubRateLimitResponse>
function M.fetch_rate_limit()
    return gh_api_call "rate_limit"
end

return M
