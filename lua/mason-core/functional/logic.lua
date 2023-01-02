local fun = require "mason-core.functional.function"

local _ = {}

---@generic T
---@param predicates (fun(item: T): boolean)[]
---@param item T
---@return boolean
_.all_pass = fun.curryN(function(predicates, item)
    for i = 1, #predicates do
        if not predicates[i](item) then
            return false
        end
    end
    return true
end, 2)

---@generic T
---@param predicates (fun(item: T): boolean)[]
---@param item T
---@return boolean
_.any_pass = fun.curryN(function(predicates, item)
    for i = 1, #predicates do
        if predicates[i](item) then
            return true
        end
    end
    return false
end, 2)

---@generic T, U
---@param predicate fun(item: T): boolean
---@param on_true fun(item: T): U
---@param on_false fun(item: T): U
---@param value T
---@return U
_.if_else = fun.curryN(function(predicate, on_true, on_false, value)
    if predicate(value) then
        return on_true(value)
    else
        return on_false(value)
    end
end, 4)

---@param value boolean
---@return boolean
_.is_not = function(value)
    return not value
end

---@generic T
---@param predicate fun(value: T): boolean
---@param value T
---@return boolean
_.complement = fun.curryN(function(predicate, value)
    return not predicate(value)
end, 2)

---@generic T, U
---@param predicate_transformer_pairs {[1]: (fun(value: T): boolean), [2]: (fun(value: T): U)}[]
---@param value T
---@return U?
_.cond = fun.curryN(function(predicate_transformer_pairs, value)
    for _, pair in ipairs(predicate_transformer_pairs) do
        local predicate, transformer = pair[1], pair[2]
        if predicate(value) then
            return transformer(value)
        end
    end
end, 2)

---@generic T
---@param default_val T
---@param val T?
---@return T
_.default_to = fun.curryN(function(default_val, val)
    if val ~= nil then
        return val
    else
        return default_val
    end
end, 2)

return _
