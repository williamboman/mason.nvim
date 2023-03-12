local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

local M = {}

local list_copy = _.list_copy

local create_bin_path = _.compose(path.concat, function(executable)
    return _.append(executable, { "bin" })
end, _.if_else(_.always(platform.is.win), _.format "%s.exe", _.identity))

---@param packages string[]
local function with_receipt(packages)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.opam(packages[1]))
        for i = 2, #packages do
            ctx.receipt:with_secondary_source(ctx.receipt.opam(packages[i]))
        end
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The opam packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The opam packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.install(packages)
    local ctx = installer.context()
    local pkgs = list_copy(packages)

    ctx.requested_version:if_present(function(version)
        pkgs[1] = ("%s.%s"):format(pkgs[1], version)
    end)

    ctx.spawn.opam {
        "install",
        "--destdir=.",
        "--yes",
        "--verbose",
        pkgs,
    }

    if packages.bin then
        _.each(function(executable)
            ctx:link_bin(executable, create_bin_path(executable))
        end, packages.bin)
    end

    return {
        with_receipt = with_receipt(packages),
    }
end

return M
