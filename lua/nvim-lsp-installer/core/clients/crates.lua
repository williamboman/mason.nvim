local fetch = require "nvim-lsp-installer.core.fetch"
local M = {}

---@alias Crate {crate: {id: string, max_stable_version: string, max_version: string, newest_version: string}}

---@param crate string
---@param callback fun(err: string|nil, data: Crate|nil)
function M.fetch_crate(crate, callback)
    fetch(("https://crates.io/api/v1/crates/%s"):format(crate), function(err, data)
        if err then
            callback(err, nil)
            return
        end
        local ok, response = pcall(vim.json.decode, data)
        if not ok then
            callback("Failed to deserialize crates.io API response.", nil)
            return
        end
        callback(nil, response)
    end)
end

return M
