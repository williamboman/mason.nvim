local Data = {}

function Data.enum(values)
    local result = {}
    for i = 1, #values do
        local v = values[i]
        result[v] = v
    end
    return result
end

function Data.set_of(list)
    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

function Data.list_reverse(list)
    local result = {}
    for i = #list, 1, -1 do
        result[#result + 1] = list[i]
    end
    return result
end

function Data.list_map(fn, list)
    local result = {}
    for i = 1, #list do
        result[#result + 1] = fn(list[i], i)
    end
    return result
end

return Data
