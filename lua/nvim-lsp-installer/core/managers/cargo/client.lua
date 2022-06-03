local fetch = require "nvim-lsp-installer.core.fetch"

local M = {}

---@alias CrateResponse {crate: {id: string, max_stable_version: string, max_version: string, newest_version: string}}

---@async
---@param crate string
---@return Result @of Crate
function M.fetch_crate(crate)
    return fetch(("https://crates.io/api/v1/crates/%s"):format(crate)):map_catching(vim.json.decode)
end

return M
