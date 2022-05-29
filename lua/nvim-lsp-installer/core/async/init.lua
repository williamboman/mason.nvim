local functional = require "nvim-lsp-installer.core.functional"
local co = coroutine

local exports = {}

local Promise = {}
Promise.__index = Promise

function Promise.new(resolver)
    return setmetatable({ resolver = resolver, has_resolved = false }, Promise)
end

---@param success boolean
---@param cb fun(success: boolean, value: table)
function Promise:_wrap_resolver_cb(success, cb)
    return function(...)
        if self.has_resolved then
            return
        end
        self.has_resolved = true
        cb(success, { ... })
    end
end

function Promise:__call(callback)
    self.resolver(self:_wrap_resolver_cb(true, callback), self:_wrap_resolver_cb(false, callback))
end

local function await(resolver)
    local ok, value = co.yield(Promise.new(resolver))
    if not ok then
        error(value[1], 2)
    end
    return unpack(value)
end

local function table_pack(...)
    return { n = select("#", ...), ... }
end

---@param async_fn fun(...)
---@param should_reject_err boolean|nil @Whether the provided async_fn takes a callback with the signature `fun(err, result)`
local function promisify(async_fn, should_reject_err)
    return function(...)
        local args = table_pack(...)
        return await(function(resolve, reject)
            if should_reject_err then
                args[args.n + 1] = function(err, result)
                    if err then
                        reject(err)
                    else
                        resolve(result)
                    end
                end
            else
                args[args.n + 1] = resolve
            end
            local ok, err = pcall(async_fn, unpack(args, 1, args.n + 1))
            if not ok then
                reject(err)
            end
        end)
    end
end

local function new_execution_context(suspend_fn, callback, ...)
    local thread = co.create(suspend_fn)
    local cancelled = false
    local step
    step = function(...)
        if cancelled then
            return
        end
        local ok, promise_or_result = co.resume(thread, ...)
        if ok then
            if co.status(thread) == "suspended" then
                if getmetatable(promise_or_result) == Promise then
                    promise_or_result(step)
                else
                    -- yield to parent coroutine
                    step(coroutine.yield(promise_or_result))
                end
            else
                callback(true, promise_or_result)
                thread = nil
            end
        else
            callback(false, promise_or_result)
            thread = nil
        end
    end

    step(...)
    return function()
        cancelled = true
        thread = nil
    end
end

exports.run = function(suspend_fn, callback, ...)
    return new_execution_context(suspend_fn, callback, ...)
end

exports.scope = function(suspend_fn)
    return function(...)
        return new_execution_context(suspend_fn, function(success, err)
            if not success then
                error(err, 0)
            end
        end, ...)
    end
end

exports.run_blocking = function(suspend_fn, ...)
    local resolved, ok, result
    local cancel_coroutine = new_execution_context(suspend_fn, function(a, b)
        resolved = true
        ok = a
        result = b
    end, ...)

    if vim.wait(60000, function()
        return resolved == true
    end, 50) then
        if not ok then
            error(result, 2)
        end
        return result
    else
        cancel_coroutine()
        error("async function failed to resolve in time.", 2)
    end
end

exports.wait = await
exports.promisify = promisify

exports.sleep = function(ms)
    await(function(resolve)
        vim.defer_fn(resolve, ms)
    end)
end

exports.scheduler = function()
    await(vim.schedule)
end

---Creates a oneshot channel that can only send once.
local function oneshot_channel()
    local has_sent = false
    local sent_value
    local saved_callback

    return {
        is_closed = function()
            return has_sent
        end,
        send = function(...)
            assert(not has_sent, "Oneshot channel can only send once.")
            has_sent = true
            sent_value = { ... }
            if saved_callback then
                saved_callback(unpack(sent_value))
            end
        end,
        receive = function()
            return await(function(resolve)
                if has_sent then
                    resolve(unpack(sent_value))
                else
                    saved_callback = resolve
                end
            end)
        end,
    }
end

---@async
---@param suspend_fns async fun()[]
exports.wait_all = function(suspend_fns)
    local channel = oneshot_channel()

    do
        local results = {}
        local thread_cancellations = {}
        local count = #suspend_fns
        local completed = 0

        for i, suspend_fn in ipairs(suspend_fns) do
            thread_cancellations[i] = exports.run(suspend_fn, function(success, result)
                completed = completed + 1
                if not success then
                    if not channel.is_closed() then
                        for _, cancel_thread in ipairs(thread_cancellations) do
                            cancel_thread()
                        end
                        channel.send(false, result)
                        results = nil
                        thread_cancellations = {}
                    end
                else
                    results[i] = result
                    if completed >= count then
                        channel.send(true, results)
                        results = nil
                        thread_cancellations = {}
                    end
                end
            end)
        end
    end

    local ok, results = channel.receive()
    if not ok then
        error(results, 2)
    end
    return unpack(results)
end

function exports.blocking(suspend_fn)
    return functional.partial(exports.run_blocking, suspend_fn)
end

return exports
