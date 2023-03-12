local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local platform = require "mason-core.platform"

local M = {}

local create_bin_path = _.if_else(_.always(platform.is.win), _.format "%s.exe", _.identity)

---@param package string
local function with_receipt(package)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.dotnet(package))
    end
end

---@async
---@param pkg string
---@param opt { bin: string[]? }?
function M.package(pkg, opt)
    return function()
        return M.install(pkg, opt).with_receipt()
    end
end

---@async
---@param pkg string
---@param opt { bin: string[]? }?
function M.install(pkg, opt)
    local ctx = installer.context()
    ctx.spawn.dotnet {
        "tool",
        "update",
        "--ignore-failed-sources",
        "--tool-path",
        ".",
        ctx.requested_version
            :map(function(version)
                return { "--version", version }
            end)
            :or_else(vim.NIL),
        pkg,
    }

    if opt and opt.bin then
        _.each(function(executable)
            ctx:link_bin(executable, create_bin_path(executable))
        end, opt.bin)
    end

    return {
        with_receipt = with_receipt(pkg),
    }
end

return M
