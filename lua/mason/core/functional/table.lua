local fun = require "mason.core.functional.function"

local _ = {}

---@param index any
---@param tbl table
_.prop = fun.curryN(function(index, tbl)
    return tbl[index]
end, 2)

---@param keys any[]
---@param tbl table
_.pick = fun.curryN(function(keys, tbl)
    local ret = {}
    for _, key in ipairs(keys) do
        ret[key] = tbl[key]
    end
    return ret
end, 2)

_.keys = fun.curryN(vim.tbl_keys, 1)
_.size = fun.curryN(vim.tbl_count, 1)

---@param tbl table<any, any>
---@return any[][]
_.to_pairs = fun.curryN(function(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        result[#result + 1] = { k, v }
    end
    return result
end, 1)

---@generic K, V
---@param tbl table<K, V>
---@return table<V, K>
_.invert = fun.curryN(function(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        result[v] = k
    end
    return result
end, 1)

return _
