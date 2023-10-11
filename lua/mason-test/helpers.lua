local InstallContext = require "mason-core.installer.context"
local InstallContextCwd = require "mason-core.installer.context.cwd"
local InstallContextFs = require "mason-core.installer.context.fs"
local InstallContextSpawn = require "mason-core.installer.context.spawn"
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
    local location = InstallLocation.new "/tmp/install-dir"
    local context_cwd = InstallContextCwd.new(location):set(location.dir)
    local context_spawn = InstallContextSpawn.new(context_cwd, handle, false)
    local context_fs = InstallContextFs.new(context_cwd)
    local context = InstallContext.new(handle, context_cwd, context_spawn, context_fs, opts and opts.install_opts or {})
    context.spawn = setmetatable({}, {
        __index = function(s, cmd)
            s[cmd] = spy.new(function()
                return Result.success { stdout = nil, stderr = nil }
            end)
            return s[cmd]
        end,
    })
    return context
end

return M
