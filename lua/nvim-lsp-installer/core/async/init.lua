local co = coroutine

local exports = {}

local Promise = {}
Promise.__index = Promise

function Promise.new(resolver)
    return setmetatable({ resolver = resolver, has_resolved = false }, Promise)
end

---@param success boolean
---@param cb fun()
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

local function promisify(async_fn)
    return function(...)
        local args = table_pack(...)
        return await(function(resolve, reject)
            args[args.n + 1] = resolve
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

exports.run = function(suspend_fn, callback)
    return new_execution_context(suspend_fn, callback)
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

return exports
