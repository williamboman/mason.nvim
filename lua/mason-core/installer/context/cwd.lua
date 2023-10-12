local Result = require "mason-core.result"
local fs = require "mason-core.fs"
local path = require "mason-core.path"

---@class InstallContextCwd
---@field private location InstallLocation Defines the upper boundary for which paths are allowed as cwd.
---@field private handle InstallHandle
---@field private cwd string?
local InstallContextCwd = {}
InstallContextCwd.__index = InstallContextCwd

---@param handle InstallHandle
---@param location InstallLocation
function InstallContextCwd.new(handle, location)
    assert(location, "location not provided")
    return setmetatable({
        location = location,
        handle = handle,
        cwd = nil,
    }, InstallContextCwd)
end

function InstallContextCwd:initialize()
    return Result.try(function(try)
        local staging_dir = self.location:staging(self.handle.package.name)
        if fs.sync.dir_exists(staging_dir) then
            try(Result.pcall(fs.sync.rmrf, staging_dir))
        end
        try(Result.pcall(fs.sync.mkdirp, staging_dir))
        self:set(staging_dir)
    end)
end

function InstallContextCwd:get()
    assert(self.cwd ~= nil, "Tried to access cwd before it was set.")
    return self.cwd
end

---@param new_abs_cwd string
function InstallContextCwd:set(new_abs_cwd)
    assert(type(new_abs_cwd) == "string", "new_cwd is not a string")
    assert(
        path.is_subdirectory(self.location:get_dir(), new_abs_cwd),
        ("%q is not a subdirectory of %q"):format(new_abs_cwd, self.location)
    )
    self.cwd = new_abs_cwd
    return self
end

return InstallContextCwd
