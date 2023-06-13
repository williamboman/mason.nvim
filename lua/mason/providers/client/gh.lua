local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local client = require "mason-core.managers.github.client"

---@type GitHubProvider
return {
    get_latest_release = function(repo)
        return client.fetch_latest_release(repo)
    end,
    get_all_release_versions = function(repo)
        return client.fetch_all_releases(repo):map(_.map(_.prop "tag_name"))
    end,
    get_all_tags = function(repo)
        return client.fetch_all_tags(repo):map(_.map(_.compose(_.gsub("^refs/tags/", ""), _.prop "ref")))
    end,
}
