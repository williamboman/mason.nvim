local _ = require "mason-core.functional"
local spawn = require "mason-core.spawn"

---@type NpmProvider
return {
    get_latest_version = function(pkg)
        return spawn
            .npm({ "view", "--json", pkg .. "@latest" })
            :map(_.prop "stdout")
            :map_catching(vim.json.decode)
            :map(_.pick { "name", "version" })
    end,
    get_all_versions = function(pkg)
        return spawn
            .npm({ "view", "--json", pkg, "versions" })
            :map(_.prop "stdout")
            :map_catching(vim.json.decode)
            :map(_.reverse)
    end,
}
