local fs = require "mason-core.fs"

local M = {}

---@async
---@param path string
---@param contents string
---@param flags string
function M.write_file(path, contents, flags)
    fs.async.write_file(
        path,
        table.concat({
            "-- THIS FILE IS GENERATED. DO NOT EDIT MANUALLY.",
            "-- stylua: ignore start",
            contents,
        }, "\n"),
        flags
    )
end

return M
