local a = require "mason-core.async"
local control = require "mason-core.async.control"
local path = require "mason-core.path"
local _ = require "mason-core.functional"
local script_utils = require "mason-scripts.utils"
local markdown = require "mason-scripts.markdown"
local spawn = require "mason-core.spawn"

local Semaphore = control.Semaphore

---@async
local function create_markdown_index()
    local registry = require "mason-registry"
    print "Creating markdown index…"
    local packages = _.sort_by(_.prop "name", registry.get_all_packages())
    local sem = Semaphore.new(10)

    a.wait_all(_.map(function(pkg)
        return function()
            local permit = sem:acquire()
            local history = spawn.git {
                "log",
                "--format=%h\t%cd\t%an\t%s",
                "--date=short",
                "--",
                path.concat { "lua", "mason-registry", pkg.name, "init.lua" },
            }
            permit:forget()
            pkg.history = _.split("\n", _.trim(history:get_or_throw().stdout))
        end
    end, packages))

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
