local InstallContext = require "mason-core.installer.context"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local control = require "mason-core.async.control"
local fs = require "mason-core.fs"
local linker = require "mason-core.installer.linker"
local log = require "mason-core.log"
local path = require "mason-core.path"
local settings = require "mason.settings"

local Semaphore = control.Semaphore

local sem = Semaphore.new(settings.current.max_concurrent_installers)

local M = {}

---@async
function M.create_prefix_dirs()
    return Result.try(function(try)
        for _, p in ipairs {
            path.install_prefix(),
            path.bin_prefix(),
            path.share_prefix(),
            path.package_prefix(),
            path.package_build_prefix(),
        } do
            if not fs.async.dir_exists(p) then
                try(Result.pcall(fs.async.mkdirp, p))
            end
        end
    end)
end

---@async
---@param context InstallContext
local function build_receipt(context)
    return Result.pcall(function()
        log.fmt_debug("Building receipt for %s", context.package)
        return context.receipt
            :with_name(context.package.name)
            :with_schema_version("1.1")
            :with_completion_time(vim.loop.gettimeofday())
            :build()
    end)
end

local CONTEXT_REQUEST = {}

---@return InstallContext
function M.context()
    return coroutine.yield(CONTEXT_REQUEST)
end

---@async
---@param ctx InstallContext
local function lock_package(ctx)
    log.debug("Attempting to lock package", ctx.package)
    local lockfile = path.package_lock(ctx.package.name)
    if not ctx.opts.force and fs.async.file_exists(lockfile) then
        log.error("Lockfile already exists.", ctx.package)
        return Result.failure(
            ("Lockfile exists, installation is already running in another process (pid: %s). Run with :MasonInstall --force to bypass."):format(
                fs.sync.read_file(lockfile)
            )
        )
    end
    a.scheduler()
    fs.async.write_file(lockfile, vim.fn.getpid())
    log.debug("Wrote lockfile", ctx.package)
    return Result.success(lockfile)
end

---@async
---@param context InstallContext
function M.prepare_installer(context)
    return Result.try(function(try)
        local package_build_prefix = path.package_build_prefix(context.package.name)
        if fs.async.dir_exists(package_build_prefix) then
            try(Result.pcall(fs.async.rmrf, package_build_prefix))
        end
        try(Result.pcall(fs.async.mkdirp, package_build_prefix))
        context.cwd:set(package_build_prefix)

        if context.package:is_registry_spec() then
            local registry_installer = require "mason-core.installer.registry"
            return try(registry_installer.compile(context.handle.package.spec, context.opts))
        else
            return context.package.spec.install
        end
    end)
end

---@generic T
---@param context InstallContext
---@param fn fun(context: InstallContext): T
---@return T
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
    step(context)
    return ret_val
end

---@async
---@param context InstallContext
---@param installer async fun(ctx: InstallContext)
local function run_installer(context, installer)
    local handle = context.handle
    return Result.pcall(function()
        return a.wait(function(resolve, reject)
            local cancel_thread = a.run(M.exec_in_context, function(success, result)
                if success then
                    resolve(result)
                else
                    reject(result)
                end
            end, context, installer)

            handle:once("terminate", function()
                cancel_thread()
                if handle:is_closed() then
                    reject "Installation was aborted."
                else
                    handle:once("closed", function()
                        reject "Installation was aborted."
                    end)
                end
            end)
        end)
    end)
end

---@async
---@param handle InstallHandle
---@param opts PackageInstallOpts
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
    local tailed_output = {}

    if opts.debug then
        local function append_log(chunk)
            tailed_output[#tailed_output + 1] = chunk
        end
        handle:on("stdout", append_log)
        handle:on("stderr", append_log)
    end

    log.fmt_info("Executing installer for %s %s", pkg, opts)

    return M.create_prefix_dirs()
        :and_then(function()
            return lock_package(context)
        end)
        :and_then(function(lockfile)
            local release_lock = _.partial(pcall, fs.async.unlink, lockfile)
            return Result.try(function(try)
                -- 1. prepare directories and initialize cwd
                local installer = try(M.prepare_installer(context))

                -- 2. execute installer
                try(run_installer(context, installer))

                -- 3. promote temporary installation dir
                try(Result.pcall(function()
                    context:promote_cwd()
                end))

                -- 4. link package
                try(linker.link(context))

                -- 5. build & write receipt
                ---@type InstallReceipt
                local receipt = try(build_receipt(context))
                try(Result.pcall(function()
                    receipt:write(context.cwd:get())
                end))
            end)
                :on_success(function()
                    release_lock()
                    if opts.debug then
                        context.fs:write_file("mason-debug.log", table.concat(tailed_output, ""))
                    end
                end)
                :on_failure(function()
                    release_lock()
                    if not opts.debug then
                        -- clean up installation dir
                        pcall(function()
                            fs.async.rmrf(context.cwd:get())
                        end)
                    else
                        context.fs:write_file("mason-debug.log", table.concat(tailed_output, ""))
                        context.stdio_sink.stdout(
                            ("[debug] Installation directory retained at %q.\n"):format(context.cwd:get())
                        )
                    end

                    -- unlink linked executables (in the occasion an error occurs after linking)
                    build_receipt(context):on_success(function(receipt)
                        linker.unlink(context.package, receipt):on_failure(function(err)
                            log.error("Failed to unlink failed installation", err)
                        end)
                    end)
                end)
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
