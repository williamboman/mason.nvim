local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"
local spawn = require "mason-core.spawn"

---@param gem string
---@param output string "$ gem list" output
local parse_gem_versions = _.curryN(function(gem, output)
    local lines = _.split("\n", output)
    return Optional.of_nilable(_.find_first(_.starts_with(gem), lines))
        :map(_.compose(_.head, _.match "%((.+)%)$"))
        :map(_.split ", ")
        :ok_or "Failed to parse gem list output."
end, 2)

---@async
---@param gem string
local function get_all_versions(gem)
    return spawn.gem({ "list", gem, "--remote", "--all" }):map(_.prop "stdout"):and_then(parse_gem_versions(gem))
end

---@type RubyGemsProvider
return {
    get_latest_version = function(gem)
        return get_all_versions(gem):map(_.head)
    end,
    get_all_versions = function(gem)
        return get_all_versions(gem)
    end,
}
