---@diagnostic disable: lowercase-global
local spy = require "luassert.spy"
local util = require "luassert.util"

local InstallContext = require "mason-core.installer.context"
local InstallHandle = require "mason-core.installer.handle"
local Result = require "mason-core.result"
local a = require "mason-core.async"
local path = require "mason-core.path"
local registry = require "mason-registry"

-- selene: allow(unused_variable)
function async_test(suspend_fn)
    return function()
        local ok, err = pcall(a.run_blocking, suspend_fn)
        if not ok then
            error(err, util.errorlevel())
        end
    end
end

-- selene: allow(unscoped_variables, incorrect_standard_library_use)
mockx = {
    just_runs = function() end,
    returns = function(val)
        return function()
            return val
        end
    end,
    throws = function(exception)
        return function()
            error(exception, 2)
        end
    end,
}

---@param opts? PackageInstallOpts
function create_dummy_context(opts)
    local ctx = InstallContextGenerator(InstallHandleGenerator "registry", opts)
    ctx.cwd:set(path.package_build_prefix "registry")
    ctx.spawn = setmetatable({}, {
        __index = function(s, cmd)
            s[cmd] = spy.new(function()
                return Result.success { stdout = nil, stderr = nil }
            end)
            return s[cmd]
        end,
    })
    return ctx
end

-- selene: allow(unused_variable)
---@param package_name string
function InstallHandleGenerator(package_name)
    return InstallHandle.new(registry.get_package(package_name))
end

-- selene: allow(unused_variable)
---@param handle InstallHandle
---@param opts PackageInstallOpts?
function InstallContextGenerator(handle, opts)
    local context = InstallContext.new(handle, opts or {})
    context.spawn = setmetatable({ strict_mode = true }, {
        __index = function(self, cmd)
            self[cmd] = spy.new(mockx.just_runs())
            return self[cmd]
        end,
    })
    return context
end
