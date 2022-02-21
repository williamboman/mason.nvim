local co = coroutine

local exports = {}

local Promise = {}
Promise.__index = Promise

function Promise.new(resolver)
    return setmetatable({ resolver = resolver }, Promise)
end

function Promise:__call(callback)
    self.resolver(function(...)
        callback(true, ...)
    end, function(...)
        callback(false, ...)
    end)
end

local function await(resolver)
    return co.yield(Promise.new(resolver))
end

local function table_pack(...)
    return { n = select("#", ...), ... }
end

local function promisify(async_fn)
    return function(...)
        local args = table_pack(...)
        return await(function(resolve)
            args[args.n + 1] = resolve
            async_fn(unpack(args, 1, args.n + 1))
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
            if getmetatable(promise_or_result) == Promise then
                promise_or_result(step)
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

exports.scope = function(suspend_fn)
    return function(...)
        return new_execution_context(suspend_fn, function() end, ...)
    end
end

exports.run_blocking = function(suspend_fn)
    local resolved, ok, result
    local cancel_coroutine = new_execution_context(suspend_fn, function(a, b)
        resolved = true
        ok = a
        result = b
    end)

    if vim.wait(60000, function()
        return resolved == true
    end, 50) then
        if not ok then
            error(result)
        end
        return result
    else
        cancel_coroutine()
        error "async function failed to resolve in time."
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

return exports
