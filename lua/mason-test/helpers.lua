local InstallContext = require "mason-core.installer.context"
local InstallHandle = require "mason-core.installer.handle"
local InstallLocation = require "mason-core.installer.location"
local Result = require "mason-core.result"
local registry = require "mason-registry"
local spy = require "luassert.spy"

local M = {}

---@param opts? { install_opts?: PackageInstallOpts, package?: string }
function M.create_context(opts)
    local pkg = registry.get_package(opts and opts.package or "dummy")
    local handle = InstallHandle.new(pkg)
    local location = InstallLocation.global()
    local context = InstallContext.new(handle, location, opts and opts.install_opts or {})
    context.spawn = setmetatable({}, {
        __index = function(s, cmd)
            s[cmd] = spy.new(function()
                return Result.success { stdout = nil, stderr = nil }
            end)
            return s[cmd]
        end,
    })
    context.cwd:initialize():get_or_throw()
    return context
end

return M
