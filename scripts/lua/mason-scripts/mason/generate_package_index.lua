local a = require "mason-core.async"
local _ = require "mason-core.functional"
local script_utils = require "mason-scripts.utils"
local markdown = require "mason-scripts.markdown"

---@async
local function create_markdown_index()
    local registry = require "mason-registry"
    require("mason-registry.sources").set_registries {
        "lua:mason-registry.index",
    }
    print "Creating markdown index…"
    local packages = _.sort_by(_.prop "name", registry.get_all_packages())

    script_utils.write_file(
        "PACKAGES.md",
        markdown.render("PACKAGES.template.md", {
            ["packages"] = packages,
        })
    )
end

a.run_blocking(function()
    create_markdown_index()
end)
