local _ = require "mason-core.functional"
local spawn = require "mason-core.spawn"

---@type GolangProvider
return {
    get_all_versions = function(pkg)
        return spawn
            .go({
                "list",
                "-json",
                "-m",
                "-versions",
                pkg,
            })
            :map(_.prop "stdout")
            :map_catching(vim.json.decode)
            :map(_.prop "Versions")
            :map(_.reverse)
    end,
}
