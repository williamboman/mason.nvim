local _ = {}

_.table_pack = function(...)
    return { n = select("#", ...), ... }
end

---@generic T : string
---@param values T[]
---@return table<T, T>
_.enum = function(values)
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
_.set_of = function(list)
    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

return _
