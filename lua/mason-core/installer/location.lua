local Path = require "mason-core.path"
local Result = require "mason-core.result"
local fs = require "mason-core.fs"

---@class InstallLocation
---@field private dir string
local InstallLocation = {}
InstallLocation.__index = InstallLocation

---@param dir string
function InstallLocation.new(dir)
    return setmetatable({
        dir = dir,
    }, InstallLocation)
end

function InstallLocation:get_dir()
    return self.dir
end

---@async
function InstallLocation:initialize()
    return Result.try(function(try)
        for _, p in ipairs {
            self.dir,
            self:bin(),
            self:share(),
            self:package(),
            self:staging(),
        } do
            if not fs.async.dir_exists(p) then
                try(Result.pcall(fs.async.mkdirp, p))
            end
        end
    end)
end

---@param path string?
function InstallLocation:bin(path)
    return Path.concat { self.dir, "bin", path }
end

---@param path string?
function InstallLocation:share(path)
    return Path.concat { self.dir, "share", path }
end

---@param path string?
function InstallLocation:package(path)
    return Path.concat { self.dir, "packages", path }
end

---@param path string?
function InstallLocation:staging(path)
    return Path.concat { self.dir, "staging", path }
end

---@param name string
function InstallLocation:lockfile(name)
    return self:staging(("%s.lock"):format(name))
end

return InstallLocation
