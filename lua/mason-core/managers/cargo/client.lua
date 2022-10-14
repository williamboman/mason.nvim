local fetch = require "mason-core.fetch"

local M = {}

---@alias CrateResponse {crate: {id: string, max_stable_version: string, max_version: string, newest_version: string}}

---@async
---@param crate string
---@return Result # Result<CrateResponse>
function M.fetch_crate(crate)
    return fetch(("https://crates.io/api/v1/crates/%s"):format(crate), {
        headers = {
            Accept = "application/json",
        },
    }):map_catching(vim.json.decode)
end

return M
