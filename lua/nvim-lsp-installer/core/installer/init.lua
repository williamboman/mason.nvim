local log = require "nvim-lsp-installer.log"
local path = require "nvim-lsp-installer.core.path"
local fs = require "nvim-lsp-installer.core.fs"
local Result = require "nvim-lsp-installer.core.result"

local M = {}

---@async
---@param context InstallContext
local function write_receipt(context)
    if context.receipt.is_marked_invalid then
        return log.fmt_debug("Skipping writing receipt for %s because it is marked as invalid.", context.name)
    end
    context.receipt:with_name(context.name):with_schema_version("1.0a"):with_completion_time(vim.loop.gettimeofday())
    local receipt_success, install_receipt = pcall(context.receipt.build, context.receipt)
    if receipt_success then
        local receipt_path = path.concat { context.cwd:get(), "nvim-lsp-installer-receipt.json" }
        pcall(fs.async.write_file, receipt_path, vim.json.encode(install_receipt))
    else
        log.fmt_error("Failed to build receipt for installation=%s, error=%s", context.name, install_receipt)
    end
end

local CONTEXT_REQUEST = {}

---@return InstallContext
function M.context()
    return coroutine.yield(CONTEXT_REQUEST)
end

---@async
---@param context InstallContext
---@param installer async fun(context: InstallContext)
function M.run_installer(context, installer)
    local thread = coroutine.create(installer)
    local step
    local ret_val
    step = function(...)
        local ok, result = coroutine.resume(thread, ...)
        if not ok then
            error(result, 0)
        elseif result == CONTEXT_REQUEST then
            step(context)
        elseif coroutine.status(thread) == "suspended" then
            -- yield to parent coroutine
            step(coroutine.yield(result))
        else
            ret_val = result
        end
    end
    step(context)
    return ret_val
end

---@async
---@param context InstallContext
---@param installer async fun(ctx: InstallContext)
function M.execute(context, installer)
    log.fmt_debug("Executing installer for name=%s", context.name)
    local tmp_installation_dir = ("%s.tmp"):format(context.destination_dir)
    return Result.run_catching(function()
        -- 1. prepare installation dir
        context.receipt:with_start_time(vim.loop.gettimeofday())
        if fs.async.dir_exists(tmp_installation_dir) then
            fs.async.rmrf(tmp_installation_dir)
        end
        fs.async.mkdirp(tmp_installation_dir)
        context.cwd:set(tmp_installation_dir)

        -- 2. run installer
        M.run_installer(context, installer)

        -- 3. finalize
        log.fmt_debug("Finalizing installer for name=%s", context.name)
        write_receipt(context)
        context:promote_cwd()
        pcall(fs.async.rmrf, tmp_installation_dir)
    end):on_failure(function(failure)
        log.fmt_error("Installation failed, name=%s, error=%s", context.name, tostring(failure))
        context.stdio_sink.stderr(tostring(failure))
        context.stdio_sink.stderr "\n"
        pcall(fs.async.rmrf, tmp_installation_dir)
        pcall(fs.async.rmrf, context.cwd:get())
    end)
end

return M
