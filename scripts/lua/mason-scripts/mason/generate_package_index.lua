local _ = require "mason-core.functional"
local a = require "mason-core.async"
local markdown = require "mason-scripts.markdown"
local script_utils = require "mason-scripts.utils"

require("mason").setup()
require("mason-registry").refresh()

---@async
local function create_markdown_index()
    local registry = require "mason-registry"
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
