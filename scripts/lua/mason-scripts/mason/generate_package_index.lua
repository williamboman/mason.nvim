local _ = require "mason-core.functional"
local a = require "mason-core.async"
local markdown = require "mason-scripts.markdown"
local script_utils = require "mason-scripts.utils"

require("mason").setup()
local registry = require "mason-registry"

---@async
local function create_markdown_index()
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
    assert(a.wait(registry.update), "Failed to update registry.")
    create_markdown_index()
end)
