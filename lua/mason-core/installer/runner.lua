local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local compiler = require "mason-core.installer.compiler"
local fs = require "mason-core.fs"
local linker = require "mason-core.installer.linker"
local log = require "mason-core.log"
local registry = require "mason-registry"

local InstallContext = require "mason-core.installer.context"

---@class InstallRunner
---@field location InstallLocation
---@field handle InstallHandle
---@field semaphore Semaphore
---@field permit Permit?
local InstallRunner = {}
InstallRunner.__index = InstallRunner

---@param location InstallLocation
---@param handle InstallHandle
---@param semaphore Semaphore
function InstallRunner.new(location, handle, semaphore)
    return setmetatable({
        location = location,
        semaphore = semaphore,
        handle = handle,
    }, InstallRunner)
end

---@param opts PackageInstallOpts
---@param callback? fun(success: boolean, result: any)
function InstallRunner:execute(opts, callback)
    local handle = self.handle
    log.fmt_info("Executing installer for %s %s", handle.package, opts)

    local context = InstallContext.new(handle, self.location, opts)

    local tailed_output = {}

    if opts.debug then
        local function append_log(chunk)
            tailed_output[#tailed_output + 1] = chunk
        end
        handle:on("stdout", append_log)
        handle:on("stderr", append_log)
    end

    ---@async
    local function finalize_logs(success, result)
        if not success then
            context.stdio_sink.stderr(tostring(result))
            context.stdio_sink.stderr "\n"
        end

        if opts.debug then
            context.fs:write_file("mason-debug.log", table.concat(tailed_output, ""))
            context.stdio_sink.stdout(("[debug] Installation directory retained at %q.\n"):format(context.cwd:get()))
        end
    end

    ---@async
    ---@param success boolean
    ---@param result InstallReceipt | any
    local finalize = a.scope(function(success, result)
        finalize_logs(success, result)

        if not opts.debug and not success then
            -- clean up installation dir
            pcall(function()
                fs.async.rmrf(context.cwd:get())
            end)
        end

        if not handle:is_closing() then
            handle:close()
        end

        self:release_lock()
        self:release_permit()

        if callback then
            callback(success, result)
        end

        if success then
            local receipt = result --[[@as InstallReceipt]]
            log.fmt_info("Installation succeeded for %s", handle.package)
            handle.package:emit("install:success", receipt)
            registry:emit("package:install:success", handle.package, receipt)
        else
            log.fmt_error("Installation failed for %s error=%s", handle.package, result)
            handle.package:emit("install:failed", result)
            registry:emit("package:install:failed", handle.package, result)
        end
    end)

    local cancel_execution = a.run(function()
        return Result.try(function(try)
            try(self:acquire_permit())
            try(self.location:initialize())
            try(self:acquire_lock(opts.force))

            context.receipt:with_start_time(vim.loop.gettimeofday())

            -- 1. initialize working directory
            try(context.cwd:initialize())

            -- 2. run installer
            ---@type async fun(ctx: InstallContext): Result
            local installer = try(compiler.compile(handle.package.spec, opts))
            try(context:execute(installer))

            -- 3. promote temporary installation dir
            try(Result.pcall(function()
                context:promote_cwd()
            end))

            -- 4. link package & write receipt
            return linker
                .link(context)
                :and_then(function()
                    return context:build_receipt(context)
                end)
                :and_then(
                    ---@param receipt InstallReceipt
                    function(receipt)
                        return receipt:write(context.cwd:get()):map(_.always(receipt))
                    end
                )
                :on_failure(function()
                    -- unlink any links that were made before failure
                    context:build_receipt():on_success(
                        ---@param receipt InstallReceipt
                        function(receipt)
                            linker.unlink(handle.package, receipt, self.location):on_failure(function(err)
                                log.error("Failed to unlink failed installation.", err)
                            end)
                        end
                    )
                end)
        end):get_or_throw()
    end, finalize)

    handle:once("terminate", function()
        cancel_execution()
        local function on_close()
            finalize(false, "Installation was aborted.")
        end
        if handle:is_closed() then
            on_close()
        else
            handle:once("closed", on_close)
        end
    end)
end

---@async
---@private
function InstallRunner:release_lock()
    pcall(fs.async.unlink, self.location:lockfile(self.handle.package.name))
end

---@async
---@param force boolean?
---@private
function InstallRunner:acquire_lock(force)
    local pkg = self.handle.package
    log.debug("Attempting to lock package", pkg)
    local lockfile = self.location:lockfile(pkg.name)
    if force ~= true and fs.async.file_exists(lockfile) then
        log.error("Lockfile already exists.", pkg)
        return Result.failure(
            ("Lockfile exists, installation is already running in another process (pid: %s). Run with :MasonInstall --force to bypass."):format(
                fs.async.read_file(lockfile)
            )
        )
    end
    a.scheduler()
    fs.async.write_file(lockfile, vim.fn.getpid())
    log.debug("Wrote lockfile", pkg)
    return Result.success(lockfile)
end

---@async
---@private
function InstallRunner:acquire_permit()
    local handle = self.handle
    if handle:is_active() or handle:is_closed() then
        log.fmt_debug("Received active or closed handle %s", handle)
        return Result.failure "Invalid handle state."
    end

    handle:queued()
    local permit = self.semaphore:acquire()
    if handle:is_closed() then
        permit:forget()
        log.fmt_trace("Installation was aborted %s", handle)
        return Result.failure "Installation was aborted."
    end
    log.fmt_trace("Activating handle %s", handle)
    handle:active()
    self.permit = permit
    return Result.success()
end

---@private
function InstallRunner:release_permit()
    if self.permit then
        self.permit:forget()
        self.permit = nil
    end
end

return InstallRunner
