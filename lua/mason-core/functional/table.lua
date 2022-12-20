local fun = require "mason-core.functional.function"

local _ = {}

---@generic T : table
---@param tbl T
---@return T
local function shallow_clone(tbl)
    local res = {}
    for k, v in pairs(tbl) do
        res[k] = v
    end
    return res
end

---@generic T, U
---@param index T
---@param tbl table<T, U>
---@return U?
_.prop = fun.curryN(function(index, tbl)
    return tbl[index]
end, 2)

---@param path any[]
---@param tbl table
_.path = fun.curryN(function(path, tbl)
    -- see https://github.com/neovim/neovim/pull/21426
    local value = vim.tbl_get(tbl, unpack(path))
    return value
end, 2)

---@generic T, U
---@param keys T[]
---@param tbl table<T, U>
---@return table<T, U>
_.pick = fun.curryN(function(keys, tbl)
    local ret = {}
    for _, key in ipairs(keys) do
        ret[key] = tbl[key]
    end
    return ret
end, 2)

_.keys = fun.curryN(vim.tbl_keys, 1)
_.size = fun.curryN(vim.tbl_count, 1)

---@generic K, V
---@param tbl table<K, V>
---@return { [1]: K, [2]: V }[]
_.to_pairs = fun.curryN(function(tbl)
    local result = {}
    for k, v in pairs(tbl) do
        result[#result + 1] = { k, v }
    end
    return result
end, 1)

---@generic K, V
---@param pairs { [1]: K, [2]: V }[]
---@return table<K, V>
_.from_pairs = fun.curryN(function(pairs)
    local result = {}
    for _, pair in ipairs(pairs) do
        result[pair[1]] = pair[2]
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

---@generic K, V
---@param transforms table<K, fun (value: V): V>
---@param tbl table<K, V>
---@return table<K, V>
_.evolve = fun.curryN(function(transforms, tbl)
    local result = shallow_clone(tbl)
    for key, value in pairs(tbl) do
        if transforms[key] then
            result[key] = transforms[key](value)
        end
    end
    return result
end, 2)

---@generic T : table
---@param left T
---@param right T
---@return T
_.merge_left = fun.curryN(function(left, right)
    return vim.tbl_extend("force", right, left)
end, 2)

---@generic K, V
---@param key K
---@param value V
---@param tbl table<K, V>
---@return table<K, V>
_.assoc = fun.curryN(function(key, value, tbl)
    local res = shallow_clone(tbl)
    res[key] = value
    return res
end, 3)

---@generic K, V
---@param key K
---@param tbl table<K, V>
---@return table<K, V>
_.dissoc = fun.curryN(function(key, tbl)
    local res = shallow_clone(tbl)
    res[key] = nil
    return res
end, 2)

return _
