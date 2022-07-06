local log = require "mason.log"
local fs = require "mason.core.fs"
local _ = require "mason.core.functional"
local pkg_index = require "mason._generated.package_index"
local Optional = require "mason.core.optional"
local path = require "mason.core.path"
local EventEmitter = require "mason.core.EventEmitter"

local M = setmetatable({}, { __index = EventEmitter })
EventEmitter.init(M)

local scan_install_root

do
    ---@type table<string, true>
    local cached_dirs

    local get_directories = _.compose(
        _.set_of,
        _.filter_map(function(entry)
            if entry.type == "directory" and pkg_index[entry.name] then
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
        ---@type string[]
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

---@param package_name string
function M.is_installed(package_name)
    return scan_install_root()[package_name] == true
end

---@param package_name string
---@return Package
function M.get_package(package_name)
    local ok, pkg = pcall(require, pkg_index[package_name])
    if not ok then
        log.error(pkg)
        error(("Cannot find package %q."):format(package_name))
    end
    return pkg
end

local get_packages = _.map(M.get_package)

---@return string[]
function M.get_installed_package_names()
    return _.keys(scan_install_root())
end

---@return Package[]
function M.get_installed_packages()
    return get_packages(M.get_installed_package_names())
end

---@return string[]
function M.get_all_package_names()
    return _.keys(pkg_index)
end

---@return Package[]
function M.get_all_packages()
    return get_packages(M.get_all_package_names())
end

return M
