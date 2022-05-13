local functional = {}

---@generic T : string
---@param values T[]
---@return table<T, T>
function functional.enum(values)
    local result = {}
    for i = 1, #values do
        local v = values[i]
        result[v] = v
    end
    return result
end

---@generic T
---@param list T[]
---@return table<T, boolean>
function functional.set_of(list)
    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

---@generic T
---@param list T[]
---@return T[]
function functional.list_reverse(list)
    local result = {}
    for i = #list, 1, -1 do
        result[#result + 1] = list[i]
    end
    return result
end

---@generic T, U
---@param fn fun(item: T): U
---@param list T[]
---@return U[]
function functional.list_map(fn, list)
    local result = {}
    for i = 1, #list do
        result[#result + 1] = fn(list[i], i)
    end
    return result
end

function functional.table_pack(...)
    return { n = select("#", ...), ... }
end

function functional.list_not_nil(...)
    local result = {}
    local args = functional.table_pack(...)
    for i = 1, args.n do
        if args[i] ~= nil then
            result[#result + 1] = args[i]
        end
    end
    return result
end

function functional.when(condition, value)
    return condition and value or nil
end

function functional.lazy_when(condition, fn)
    return condition and fn() or nil
end

function functional.coalesce(...)
    local args = functional.table_pack(...)
    for i = 1, args.n do
        local variable = args[i]
        if variable ~= nil then
            return variable
        end
    end
end

---@generic T
---@param list T[]
---@return T[] @A shallow copy of the list.
function functional.list_copy(list)
    local result = {}
    for i = 1, #list do
        result[#result + 1] = list[i]
    end
    return result
end

---@generic T
---@param predicate fun(item: T): boolean
---@param list T[]
---@return T | nil
function functional.list_find_first(predicate, list)
    local result
    for i = 1, #list do
        local entry = list[i]
        if predicate(entry) then
            return entry
        end
    end
    return result
end

---@generic T
---@param predicate fun(item: T): boolean
---@param list T[]
---@return boolean
function functional.list_any(predicate, list)
    for i = 1, #list do
        if predicate(list[i]) then
            return true
        end
    end
    return false
end

function functional.identity(a)
    return a
end

function functional.always(a)
    return function()
        return a
    end
end

---@generic T : fun(...)
---@param fn T
---@param cache_key_generator (fun(...): string | nil)|nil
---@return T
function functional.memoize(fn, cache_key_generator)
    cache_key_generator = cache_key_generator or functional.identity
    local cache = {}
    return function(...)
        local key = cache_key_generator(...)
        if not cache[key] then
            cache[key] = functional.table_pack(fn(...))
        end
        return unpack(cache[key], 1, cache[key].n)
    end
end

---@generic T
---@param fn fun(): T
---@return fun(): T
function functional.lazy(fn)
    local memoized = functional.memoize(fn, functional.always "lazyval")
    return function()
        return memoized()
    end
end

---@generic T
---@param fn fun(...): T
---@return fun(...): T
function functional.partial(fn, ...)
    local bound_args = functional.table_pack(...)
    return function(...)
        local args = functional.table_pack(...)
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

function functional.compose(...)
    local functions = functional.table_pack(...)
    assert(functions.n > 0, "compose requires at least one function")
    return function(...)
        local result = functional.table_pack(...)
        for i = functions.n, 1, -1 do
            result = functional.table_pack(functions[i](unpack(result, 1, result.n)))
        end
        return unpack(result, 1, result.n)
    end
end

---@generic T
---@param filter_fn fun(item: T): boolean
---@return fun(list: T[]): T[]
function functional.filter(filter_fn)
    return functional.partial(vim.tbl_filter, filter_fn)
end

---@generic T
---@param fn fun(item: T, index: integer)
---@param list T[]
function functional.each(fn, list)
    for k, v in pairs(list) do
        fn(v, k)
    end
end

---@generic T
---@param predicates (fun(item: T): boolean)[]
---@return fun(item: T): boolean
function functional.all_pass(predicates)
    return function(item)
        for i = 1, #predicates do
            if not predicates[i](item) then
                return false
            end
        end
        return true
    end
end

---@generic T
---@param predicate fun(item: T): boolean
---@return fun(item: T): boolean
function functional.negate(predicate)
    return function(...)
        return not predicate(...)
    end
end

---@param index any
---@return fun(obj: table): any
function functional.prop(index)
    return function(obj)
        return obj[index]
    end
end

---@param condition fun(...): boolean
---@param a fun(...): any
---@param b fun(...): any
---@return fun(...): any
function functional.if_else(condition, a, b)
    return function(...)
        if condition(...) then
            return a(...)
        else
            return b(...)
        end
    end
end

---@param pattern string
function functional.matches(pattern)
    ---@param str string
    return function(str)
        return str:match(pattern) ~= nil
    end
end

functional.T = functional.always(true)
functional.F = functional.always(false)

return functional
