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

return _
