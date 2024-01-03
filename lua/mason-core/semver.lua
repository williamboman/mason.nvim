local Result = require "mason-core.result"
local semver = require "mason-vendor.semver"

local M = {}

---@param version string
---@return Semver
function M.new(version)
    version = version:gsub("^v", "")
    return semver(version)
end

---@param version string
---@return Result # Result<Semver>
function M.parse(version)
    return Result.pcall(M.new, version)
end

return M
