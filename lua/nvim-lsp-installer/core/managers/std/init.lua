local a = require "nvim-lsp-installer.core.async"
local installer = require "nvim-lsp-installer.core.installer"

local M = {}

local function with_system_executable_receipt(executable)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.system(executable))
    end
end

---@async
---@param executable string
---@param opts {help_url:string|nil}
function M.system_executable(executable, opts)
    return function()
        M.ensure_executable(executable, opts).with_receipt()
    end
end

---@async
---@param executable string
---@param opts {help_url:string|nil}
function M.ensure_executable(executable, opts)
    local ctx = installer.context()
    opts = opts or {}
    if vim.in_fast_event() then
        a.scheduler()
    end
    if vim.fn.executable(executable) ~= 1 then
        ctx.stdio_sink.stderr(("%s was not found in path.\n"):format(executable))
        if opts.help_url then
            ctx.stdio_sink.stderr(("See %s for installation instructions.\n"):format(opts.help_url))
        end
        error("Installation failed: system executable was not found.", 0)
    end

    return {
        with_receipt = with_system_executable_receipt(executable),
    }
end

return M
