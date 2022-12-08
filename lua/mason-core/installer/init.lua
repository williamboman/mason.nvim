local log = require "mason-core.log"
local _ = require "mason-core.functional"
local path = require "mason-core.path"
local fs = require "mason-core.fs"
local a = require "mason-core.async"
local Result = require "mason-core.result"
local InstallContext = require "mason-core.installer.context"
local settings = require "mason.settings"
local linker = require "mason-core.installer.linker"
local control = require "mason-core.async.control"

local Semaphore = control.Semaphore

local sem = Semaphore.new(settings.current.max_concurrent_installers)

local M = {}

---@async
local function create_prefix_dirs()
    for _, p in ipairs { path.install_prefix(), path.bin_prefix(), path.package_prefix(), path.package_build_prefix() } do
        if not fs.async.dir_exists(p) then
            fs.async.mkdirp(p)
        end
    end
end

---@async
---@param context InstallContext
local function write_receipt(context)
    log.fmt_debug("Writing receipt for %s", context.package)
    context.receipt
        :with_name(context.package.name)
        :with_schema_version("1.0")
        :with_completion_time(vim.loop.gettimeofday())
    local receipt_path = path.concat { context.cwd:get(), "mason-receipt.json" }
    local install_receipt = context.receipt:build()
    fs.async.write_file(receipt_path, vim.json.encode(install_receipt))
end

local CONTEXT_REQUEST = {}

---@return InstallContext
function M.context()
    return coroutine.yield(CONTEXT_REQUEST)
end

---@async
---@param context InstallContext
function M.prepare_installer(context)
    create_prefix_dirs()
    local package_build_prefix = path.package_build_prefix(context.package.name)
    if fs.async.dir_exists(package_build_prefix) then
        fs.async.rmrf(package_build_prefix)
    end
    fs.async.mkdirp(package_build_prefix)
    context.cwd:set(package_build_prefix)
end

---@async
---@param context InstallContext
---@param fn async fun(context: InstallContext)
function M.exec_in_context(context, fn)
    local thread = coroutine.create(function(...)
        -- We wrap the function to allow it to be a spy instance (in which case it's not actually a function, but a
        -- callable metatable - coroutine.create strictly expects functions only)
        return fn(...)
    end)
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
    context.receipt:with_start_time(vim.loop.gettimeofday())
    M.prepare_installer(context)
    step(context)
    return ret_val
end

---@async
---@param handle InstallHandle
---@param opts InstallContextOpts
function M.execute(handle, opts)
    if handle:is_active() or handle:is_closed() then
        log.fmt_debug("Received active or closed handle %s", handle)
        return Result.failure "Invalid handle state."
    end

    handle:queued()
    local permit = sem:acquire()
    if handle:is_closed() then
        permit:forget()
        log.fmt_trace("Installation was aborted %s", handle)
        return Result.failure "Installation was aborted."
    end
    log.fmt_trace("Activating handle %s", handle)
    handle:active()

    local pkg = handle.package
    local context = InstallContext.new(handle, opts)

    if opts.debug then
        local append_log = a.scope(function(chunk)
            context.fs:append_file("mason-debug.log", chunk)
        end)
        handle:on("stdout", append_log)
        handle:on("stderr", append_log)
    end

    log.fmt_info("Executing installer for %s", pkg)
    return Result.run_catching(function()
        -- 1. run installer
        a.wait(function(resolve, reject)
            local cancel_thread = a.run(M.exec_in_context, function(success, result)
                if success then
                    resolve(result)
                else
                    reject(result)
                end
            end, context, pkg.spec.install)

            handle:once("terminate", function()
                handle:once("closed", function()
                    reject "Installation was aborted."
                end)
                cancel_thread()
            end)
        end)

        -- 2. promote temporary installation dir
        context:promote_cwd()

        -- 3. link package
        linker.link(context)

        -- 4. write receipt
        write_receipt(context)
    end)
        :on_success(function()
            permit:forget()
            handle:close()
            log.fmt_info("Installation succeeded for %s", pkg)
        end)
        :on_failure(function(failure)
            permit:forget()
            log.fmt_error("Installation failed for %s error=%s", pkg, failure)
            context.stdio_sink.stderr(tostring(failure))
            context.stdio_sink.stderr "\n"

            if not opts.debug then
                -- clean up installation dir
                pcall(function()
                    fs.async.rmrf(context.cwd:get())
                end)
            else
                context.stdio_sink.stdout(
                    ("[debug] Installation directory retained at %q.\n"):format(context.cwd:get())
                )
            end

            -- unlink linked executables (in the rare occasion an error occurs after linking)
            linker.unlink(context.package, context.receipt.links)

            if not handle:is_closed() and not handle.is_terminated then
                handle:close()
            end
        end)
end

---Runs the provided async functions concurrently and returns their result, once all are resolved.
---This is really just a wrapper around a.wait_all() that makes sure to patch the coroutine context before creating the
---new async execution contexts.
---@async
---@param suspend_fns async fun(ctx: InstallContext)[]
function M.run_concurrently(suspend_fns)
    local context = M.context()
    return a.wait_all(_.map(function(suspend_fn)
        return _.partial(M.exec_in_context, context, suspend_fn)
    end, suspend_fns))
end

return M
