local fun = require "mason-core.functional.function"

local _ = {}

_.equals = fun.curryN(function(expected, value)
    return value == expected
end, 2)

_.prop_eq = fun.curryN(function(property, value, tbl)
    return tbl[property] == value
end, 3)

_.prop_satisfies = fun.curryN(function(predicate, property, tbl)
    return predicate(tbl[property])
end, 3)

---@param predicate fun(value: any): boolean
---@param path any[]
---@param tbl table
_.path_satisfies = fun.curryN(function(predicate, path, tbl)
    return predicate(vim.tbl_get(tbl, unpack(path)))
end, 3)

---@param a number
---@param b number
---@return number
_.min = fun.curryN(function(a, b)
    return b - a
end, 2)

---@param a number
---@param b number
---@return number
_.add = fun.curryN(function(a, b)
    return b + a
end, 2)

return _
