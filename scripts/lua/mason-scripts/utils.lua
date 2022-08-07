local _ = require "mason-core.functional"
local Path = require "mason-core.path"
local fs = require "mason-core.fs"

local M = {}

---@async
---@param path string
---@param contents string
---@param flags string
function M.write_file(path, contents, flags)
    local header = _.cond {
        { _.matches "%.md$", _.always { "<!--- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY. -->" } },
        {
            _.matches "%.lua$",
            _.always {
                "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
                "-- stylua: ignore start",
            },
        },
        { _.T, _.always { "// THIS FILE IS GENERATED. DO NOT EDIT MANUALLY." } },
    }(path)
    fs.async.write_file(path, _.join("\n", _.concat(header, { contents })), flags)
end

---@param path string
---@return string
function M.rel_path(path)
    local script_path = debug.getinfo(2, "S").source:sub(2):match "(.*/)"
    return Path.concat { script_path, path }
end

return M
