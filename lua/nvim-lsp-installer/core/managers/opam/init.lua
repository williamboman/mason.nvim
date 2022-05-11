local functional = require "nvim-lsp-installer.core.functional"
local path = require "nvim-lsp-installer.core.path"
local process = require "nvim-lsp-installer.core.process"
local installer = require "nvim-lsp-installer.core.installer"

local M = {}

local list_copy = functional.list_copy

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
---@param packages string[] @The opam packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages string[] @The opam packages to install. The first item in this list will be the recipient of the requested version, if set.
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

    return {
        with_receipt = with_receipt(packages),
    }
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { path.concat { root_dir, "bin" } },
    }
end

return M
