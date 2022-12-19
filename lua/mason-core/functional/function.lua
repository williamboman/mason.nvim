local data = require "mason-core.functional.data"

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

---@generic T
---@param value T
---@return T
_.identity = function(value)
    return value
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
---@param cache_key_generator (fun(...): any)?
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

_.tap = _.curryN(function(fn, value)
    fn(value)
    return value
end, 2)

---@generic T, U
---@param value T
---@param fn fun(value: T): U
---@return U
_.apply_to = _.curryN(function(value, fn)
    return fn(value)
end, 2)

---@generic T, R, V
---@param fn fun (args...: V[]): R
---@param args V[]
---@return R
_.apply = _.curryN(function(fn, args)
    return fn(unpack(args))
end, 2)

---@generic T, V
---@param fn fun(...): T
---@param fns (fun(value: V))[]
---@param val V
---@return T
_.converge = _.curryN(function(fn, fns, val)
    return fn(unpack(vim.tbl_map(_.apply_to(val), fns)))
end, 3)

---@param spec table
---@param value any
---@return table
_.apply_spec = _.curryN(function(spec, value)
    spec = vim.deepcopy(spec)
    local function transform(item)
        if type(item) == "table" then
            for k, v in pairs(item) do
                item[k] = transform(v)
            end
            return item
        else
            return item(value)
        end
    end
    return transform(spec)
end, 2)

return _
