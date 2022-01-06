---@class VersionCheckResult
---@field public server Server
---@field public success boolean
---@field public outdated_packages OutdatedPackage[]
local VersionCheckResult = {}
VersionCheckResult.__index = VersionCheckResult

---@alias OutdatedPackage {name: string, current_version: string, latest_version: string}

---@param server Server
---@param outdated_packages OutdatedPackage[]
function VersionCheckResult.new(server, success, outdated_packages)
    local self = setmetatable({}, VersionCheckResult)
    self.server = server
    self.success = success
    self.outdated_packages = outdated_packages
    return self
end

---@param server Server
function VersionCheckResult.fail(server)
    return VersionCheckResult.new(server, false)
end

---@param server Server
---@param outdated_packages OutdatedPackage[]
function VersionCheckResult.success(server, outdated_packages)
    return VersionCheckResult.new(server, true, outdated_packages)
end

function VersionCheckResult.empty(server)
    return VersionCheckResult.success(server, {})
end

function VersionCheckResult:has_outdated_packages()
    return #self.outdated_packages > 0
end

return VersionCheckResult
