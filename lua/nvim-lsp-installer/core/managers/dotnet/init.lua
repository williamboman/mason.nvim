local process = require "nvim-lsp-installer.core.process"
local installer = require "nvim-lsp-installer.core.installer"

local M = {}

---@param package string
local function with_receipt(package)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.dotnet(package))
    end
end

---@async
---@param package string
function M.package(package)
    return function()
        return M.install(package).with_receipt()
    end
end

---@async
---@param package string
function M.install(package)
    local ctx = installer.context()
    ctx.spawn.dotnet {
        "tool",
        "update",
        "--tool-path",
        ".",
        ctx.requested_version
            :map(function(version)
                return { "--version", version }
            end)
            :or_else(vim.NIL),
        package,
    }

    return {
        with_receipt = with_receipt(package),
    }
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { root_dir },
    }
end

return M
