local log = require "mason-core.log"
local fs = require "mason-core.fs"
local _ = require "mason-core.functional"
local Optional = require "mason-core.optional"
local path = require "mason-core.path"
local EventEmitter = require "mason-core.EventEmitter"

local index = require "mason-registry.index"

---@class MasonRegistry : EventEmitter
---@diagnostic disable-next-line: assign-type-mismatch
local M = setmetatable({}, { __index = EventEmitter })
EventEmitter.init(M)

local scan_install_root

do
    ---@type table<string, true>?
    local cached_dirs

    local get_directories = _.compose(
        _.set_of,
        _.filter_map(function(entry)
            if entry.type == "directory" and index[entry.name] then
                return Optional.of(entry.name)
            else
                return Optional.empty()
            end
        end)
    )

    ---@return table<string, true>
    scan_install_root = function()
        if cached_dirs then
            return cached_dirs
        end
        log.trace "Scanning installation root dir"
        local ok, entries = pcall(fs.sync.readdir, path.package_prefix())
        if not ok then
            log.debug("Failed to scan installation root dir", entries)
            -- presume installation root dir has not been created yet (i.e., no packages installed)
            return {}
        end
        cached_dirs = get_directories(entries)
        vim.schedule(function()
            cached_dirs = nil
        end)
        log.trace("Resolved installation root dirs", cached_dirs)
        return cached_dirs
    end
end

---Checks whether the provided package name is installed.
---In many situations, this is a more efficient option than the Package:is_installed() method due to a smaller amount of
---modules required to load.
---@param package_name string
function M.is_installed(package_name)
    return scan_install_root()[package_name] == true
end

---Returns an instance of the Package class if the provided package name exists. This function errors if a package cannot be found.
---@param package_name string
---@return Package
function M.get_package(package_name)
    local ok, pkg = pcall(require, index[package_name])
    if not ok then
        log.error(pkg)
        error(("Cannot find package %q."):format(package_name))
    end
    return pkg
end

local get_packages = _.map(M.get_package)

---Returns all installed package names. This is a fast function that doesn't load any extra modules.
---@return string[]
function M.get_installed_package_names()
    return _.keys(scan_install_root())
end

---Returns all installed package instances. This is a slower function that loads more modules.
---@return Package[]
function M.get_installed_packages()
    return get_packages(M.get_installed_package_names())
end

---Returns all package names. This is a fast function that doesn't load any extra modules.
---@return string[]
function M.get_all_package_names()
    return _.keys(index)
end

---Returns all package instances. This is a slower function that loads more modules.
---@return Package[]
function M.get_all_packages()
    return get_packages(M.get_all_package_names())
end

return M
