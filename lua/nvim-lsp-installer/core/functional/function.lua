local data = require "nvim-lsp-installer.core.functional.data"

local _ = {}

---@generic T : fun(...)
---@param fn T
---@param arity integer
---@return T
_.curryN = function(fn, arity)
    return function(...)
        local args = data.table_pack(...)
        if args.n >= arity then
            return fn(unpack(args, 1, arity))
        else
            return _.curryN(_.partial(fn, unpack(args, 1, args.n)), arity - args.n)
        end
    end
end

_.compose = function(...)
    local functions = data.table_pack(...)
    assert(functions.n > 0, "compose requires at least one function")
    return function(...)
        local result = data.table_pack(...)
        for i = functions.n, 1, -1 do
            result = data.table_pack(functions[i](unpack(result, 1, result.n)))
        end
        return unpack(result, 1, result.n)
    end
end

---@generic T
---@param fn fun(...): T
---@return fun(...): T
_.partial = function(fn, ...)
    local bound_args = data.table_pack(...)
    return function(...)
        local args = data.table_pack(...)
        local merged_args = {}
        for i = 1, bound_args.n do
            merged_args[i] = bound_args[i]
        end
        for i = 1, args.n do
            merged_args[bound_args.n + i] = args[i]
        end
        return fn(unpack(merged_args, 1, bound_args.n + args.n))
    end
end

_.identity = function(a)
    return a
end

_.always = function(a)
    return function()
        return a
    end
end

_.T = _.always(true)
_.F = _.always(false)

---@generic T : fun(...)
---@param fn T
---@param cache_key_generator (fun(...): string | nil)|nil
---@return T
_.memoize = function(fn, cache_key_generator)
    cache_key_generator = cache_key_generator or _.identity
    local cache = {}
    return function(...)
        local key = cache_key_generator(...)
        if not cache[key] then
            cache[key] = data.table_pack(fn(...))
        end
        return unpack(cache[key], 1, cache[key].n)
    end
end

---@generic T
---@param fn fun(): T
---@return fun(): T
_.lazy = function(fn)
    local memoized = _.memoize(fn, _.always "lazyval")
    return function()
        return memoized()
    end
end

return _
