local semver = require "mason-vendor.semver"
local Result = require "mason-core.result"

local M = {}

---@param version string
function M.parse(version)
    version = version:gsub("^v", "")
    return Result.pcall(semver, version)
end

return M
