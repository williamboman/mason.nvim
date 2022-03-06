local fetch = require "nvim-lsp-installer.core.fetch"
local Data = require "nvim-lsp-installer.data"
local log = require "nvim-lsp-installer.log"

local list_find_first = Data.list_find_first

local M = {}

---@alias GitHubRelease {tag_name:string, prerelease: boolean, draft: boolean}
---@alias GitHubTag {name: string}

---@param repo string The GitHub repo ("username/repo").
---@param callback fun(error: string|nil, data: GitHubRelease[]|nil)
function M.fetch_releases(repo, callback)
    log.fmt_trace("Fetching GitHub releases for repo=%s", repo)
    fetch(("https://api.github.com/repos/%s/releases"):format(repo), {
        custom_fetcher = {
            cmd = "gh",
            args = { "api", ("repos/%s/releases"):format(repo) },
        },
    }, function(err, response)
        if err then
            log.fmt_error("Failed to fetch releases for repo=%s", repo)
            return callback("Failed to fetch GitHub releases.", nil)
        end
        callback(nil, vim.json.decode(response))
    end)
end

---@alias FetchLatestGithubReleaseOpts {tag_name_pattern:string}
---@param repo string The GitHub repo ("username/repo").
---@param opts FetchLatestGithubReleaseOpts|nil
---@param callback fun(error: string|nil, data: GitHubRelease|nil)
function M.fetch_latest_release(repo, opts, callback)
    M.fetch_releases(repo, function(err, releases)
        if err then
            callback(err, nil)
            return
        end

        local latest_release = list_find_first(releases, function(_release)
            ---@type GitHubRelease
            local release = _release
            local is_stable_release = not release.prerelease and not release.draft
            if opts.tag_name_pattern then
                return is_stable_release and release.tag_name:match(opts.tag_name_pattern)
            end
            return is_stable_release
        end)

        if not latest_release then
            log.fmt_info("Failed to find latest release. repo=%s, opts=%s", repo, opts)
            return callback("Failed to find latest release.", nil)
        end

        log.fmt_debug("Resolved latest version repo=%s, tag_name=%s", repo, latest_release.tag_name)
        callback(nil, latest_release)
    end)
end

---@param repo string The GitHub repo ("username/repo").
---@param callback fun(err: string|nil, tags: GitHubTag[]|nil)
function M.fetch_tags(repo, callback)
    fetch(("https://api.github.com/repos/%s/tags"):format(repo), {
        custom_fetcher = {
            cmd = "gh",
            args = { "api", ("repos/%s/tags"):format(repo) },
        },
    }, function(err, response)
        if err then
            log.fmt_error("Failed to fetch tags for repo=%s", err)
            return callback("Failed to fetch tags.", nil)
        end
        callback(nil, vim.json.decode(response))
    end)
end

---@param repo string The GitHub repo ("username/repo").
---@param callback fun(err: string|nil, latest_tag: GitHubTag|nil)
function M.fetch_latest_tag(repo, callback)
    M.fetch_tags(repo, function(err, tags)
        if err then
            return callback(err, nil)
        end
        if vim.tbl_count(tags) == 0 then
            return callback("No tags found.", nil)
        end
        callback(nil, tags[1])
    end)
end

return M
