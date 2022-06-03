local fun = require "nvim-lsp-installer.core.functional.function"
local data = require "nvim-lsp-installer.core.functional.data"

local _ = {}

---@generic T
---@param list T[]
---@return T[]
_.reverse = function(list)
    local result = {}
    for i = #list, 1, -1 do
        result[#result + 1] = list[i]
    end
    return result
end

_.list_not_nil = function(...)
    local result = {}
    local args = data.table_pack(...)
    for i = 1, args.n do
        if args[i] ~= nil then
            result[#result + 1] = args[i]
        end
    end
    return result
end

---@generic T
---@param predicate fun(item: T): boolean
---@param list T[]
---@return T | nil
_.find_first = fun.curryN(function(predicate, list)
    local result
    for i = 1, #list do
        local entry = list[i]
        if predicate(entry) then
            return entry
        end
    end
    return result
end, 2)

---@generic T
---@param predicate fun(item: T): boolean
---@param list T[]
---@return boolean
_.any = fun.curryN(function(predicate, list)
    for i = 1, #list do
        if predicate(list[i]) then
            return true
        end
    end
    return false
end, 2)

---@generic T
---@param filter_fn fun(item: T): boolean
---@return fun(list: T[]): T[]
_.filter = fun.curryN(vim.tbl_filter, 2)

---@generic T
---@param map_fn fun(item: T): boolean
---@return fun(list: T[]): T[]
_.map = fun.curryN(vim.tbl_map, 2)

---@generic T
---@param fn fun(item: T, index: integer)
---@param list T[]
_.each = fun.curryN(function(fn, list)
    for k, v in pairs(list) do
        fn(v, k)
    end
end, 2)

---@generic T
---@param list T[]
---@return T[] @A shallow copy of the list.
_.list_copy = _.map(fun.identity)

_.concat = fun.curryN(function(a, b)
    if type(a) == "table" then
        assert(type(b) == "table", "concat: expected table")
        return vim.list_extend(_.list_copy(a), b)
    elseif type(a) == "string" then
        assert(type(b) == "string", "concat: expected string")
        return a .. b
    end
end, 2)

---@generic T
---@generic U
---@param keys T[]
---@param values U[]
---@return table<T, U>
_.zip_table = fun.curryN(function(keys, values)
    local res = {}
    for i, key in ipairs(keys) do
        res[key] = values[i]
    end
    return res
end, 2)

---@generic T
---@param offset number
---@param value T[]|string
---@return T|string|nil
_.nth = fun.curryN(function(offset, value)
    local index = offset < 0 and (#value + (offset + 1)) or offset
    if type(value) == "string" then
        return string.sub(value, index, index)
    else
        return value[index]
    end
end, 2)

_.head = _.nth(1)

---@param value string|any[]
_.length = function(value)
    return #value
end

return _
