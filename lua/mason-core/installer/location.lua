local Path = require "mason-core.path"
local platform = require "mason-core.platform"
local settings = require "mason.settings"

---@class InstallLocation
---@field private dir string
local InstallLocation = {}
InstallLocation.__index = InstallLocation

---@param dir string
function InstallLocation:new(dir)
    ---@type InstallLocation
    local instance = {}
    setmetatable(instance, self)
    instance.dir = dir
    return instance
end

function InstallLocation.global()
    return InstallLocation:new(settings.current.install_root_dir)
end

function InstallLocation:get_dir()
    return self.dir
end

---@async
function InstallLocation:initialize()
    local Result = require "mason-core.result"
    local fs = require "mason-core.fs"

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
function InstallLocation:opt(path)
    return Path.concat { self.dir, "opt", path }
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

---@param path string
function InstallLocation:registry(path)
    return Path.concat { self.dir, "registries", path }
end

---@param opts { PATH: '"append"' | '"prepend"' | '"skip"' }
function InstallLocation:set_env(opts)
    vim.env.MASON = self.dir

    if opts.PATH == "prepend" then
        vim.env.PATH = self:bin() .. platform.path_sep .. vim.env.PATH
    elseif opts.PATH == "append" then
        vim.env.PATH = vim.env.PATH .. platform.path_sep .. self:bin()
    end
end

return InstallLocation
