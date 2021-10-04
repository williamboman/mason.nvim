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

function Data.tbl_pack(...)
    return { n = select("#", ...), ... }
end

function Data.when(condition, value)
    return condition and value or nil
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

function Data.list_copy(list)
    local result = {}
    for i = 1, #list do
        result[#result + 1] = list[i]
    end
    return result
end

function Data.list_any(list, predicate)
    for i = 1, #list do
        if predicate(list[i]) then
            return true
        end
    end
    return false
end

function Data.json_decode(data)
    if vim.json and vim.json.decode then
        return vim.json.decode(data)
    else
        return vim.fn.json_decode(data)
    end
end

return Data
