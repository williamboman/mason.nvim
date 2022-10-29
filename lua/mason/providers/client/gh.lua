local spawn = require "mason-core.spawn"
local _ = require "mason-core.functional"
local Result = require "mason-core.result"
local Optional = require "mason-core.optional"

---@type GitHubProvider
return {
    get_latest_release = function(repo, opts)
        opts = opts or {}
        if not opts.include_prerelease then
            return spawn
                .gh({ "api", ("repos/%s/releases/latest"):format(repo) })
                :map(_.prop "stdout")
                :map_catching(vim.json.decode)
        else
            return spawn
                .gh({ "api", ("repos/%s/releases"):format(repo) })
                :map(_.prop "stdout")
                :map_catching(vim.json.decode)
                :map(_.find_first(_.prop_eq("draft", false)))
                :and_then(function(release)
                    return Optional.of_nilable(release):ok_or "Failed to find latest release."
                end)
        end
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
