local spawn = require "mason-core.spawn"
local _ = require "mason-core.functional"
local Result = require "mason-core.result"

---@type GitHubProvider
return {
    get_latest_release = function(repo)
        return spawn
            .gh({ "api", ("repos/%s/releases/latest"):format(repo) })
            :map(_.prop "stdout")
            :map_catching(vim.json.decode)
    end,
    get_all_release_versions = function(repo)
        return spawn
            .gh({ "api", ("repos/%s/releases"):format(repo) })
            :map(_.prop "stdout")
            :map_catching(vim.json.decode)
            :map(_.map(_.prop "tag_name"))
    end,
    get_latest_tag = function(repo)
        return Result.failure "Unimplemented"
    end,
    get_all_tags = function(repo)
        return spawn
            .gh({ "api", ("repos/%s/git/matching-refs/tags"):format(repo) })
            :map(_.prop "stdout")
            :map_catching(vim.json.decode)
            :map(_.map(_.compose(_.gsub("^refs/tags/", ""), _.prop "ref")))
    end,
}
