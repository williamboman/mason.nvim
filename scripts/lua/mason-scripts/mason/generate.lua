local _ = require "mason-core.functional"
local a = require "mason-core.async"
local path = require "mason-core.path"
local script_utils = require "mason-scripts.utils"

local MASON_DIR = path.concat { vim.loop.cwd(), "lua", "mason" }

require("mason").setup()
local registry = require "mason-registry"

---@async
local function create_language_map()
    print "Creating language map…"
    local indexed_languages = {}
    local language_map = {}
    local sorted_packages = _.sort_by(_.prop "name", registry.get_all_packages())
    _.each(function(pkg)
        _.each(function(language)
            local language_lc = language:lower()
            if indexed_languages[language_lc] and indexed_languages[language_lc] ~= language then
                error(
                    ("Found two variants of same language with differing cases %s != %s"):format(
                        indexed_languages[language_lc],
                        language
                    )
                )
            end
            indexed_languages[language_lc] = language
            language_map[language_lc] = _.append(pkg.name, language_map[language_lc] or {})
        end, pkg.spec.languages)
    end, sorted_packages)

    script_utils.write_file(
        path.concat { MASON_DIR, "mappings", "language.lua" },
        "return " .. vim.inspect(language_map),
        "w"
    )
end
a.run_blocking(function()
    assert(a.wait(registry.update), "Failed to update registry.")
    create_language_map()
end)
