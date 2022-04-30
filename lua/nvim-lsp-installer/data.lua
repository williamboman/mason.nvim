-- TODO: rename this to functional.lua, long overdue

local Data = {}

---@generic T : string
---@param values T[]
---@return table<T, T>
function Data.enum(values)
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
function Data.set_of(list)
    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

---@generic T
---@param list T[]
---@return T[]
function Data.list_reverse(list)
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
function Data.list_map(fn, list)
    local result = {}
    for i = 1, #list do
        result[#result + 1] = fn(list[i], i)
    end
    return result
end

function Data.table_pack(...)
    return { n = select("#", ...), ... }
end

function Data.list_not_nil(...)
    local result = {}
    local args = Data.table_pack(...)
    for i = 1, args.n do
        if args[i] ~= nil then
            result[#result + 1] = args[i]
        end
    end
    return result
end

function Data.tbl_pack(...)
    return { n = select("#", ...), ... }
end

function Data.when(condition, value)
    return condition and value or nil
end

function Data.lazy_when(condition, fn)
    return condition and fn() or nil
end

function Data.coalesce(...)
    local args = Data.tbl_pack(...)
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
function Data.list_copy(list)
    local result = {}
    for i = 1, #list do
        result[#result + 1] = list[i]
    end
    return result
end

---@generic T
---@param list T[]
---@param predicate fun(item: T): boolean
---@return T | nil
function Data.list_find_first(list, predicate)
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
---@param list T[]
---@param predicate fun(item: T): boolean
---@return boolean
function Data.list_any(list, predicate)
    for i = 1, #list do
        if predicate(list[i]) then
            return true
        end
    end
    return false
end

function Data.identity(a)
    return a
end

---@generic T : fun(...)
---@param fn T
---@param cache_key_generator (fun(...): string | nil)|nil
---@return T
function Data.memoize(fn, cache_key_generator)
    cache_key_generator = cache_key_generator or Data.identity
    local cache = {}
    return function(...)
        local key = cache_key_generator(...)
        if not cache[key] then
            cache[key] = fn(...)
        end
        return cache[key]
    end
end

function Data.lazy(fn)
    local ret_val
    return function()
        if not ret_val then
            ret_val = Data.table_pack(fn())
        end
        return unpack(ret_val, 1, ret_val.n)
    end
end

return Data
