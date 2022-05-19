local fun = require "nvim-lsp-installer.core.functional.function"

local _ = {}

---@generic T
---@param predicates (fun(item: T): boolean)[]
---@return fun(item: T): boolean
_.all_pass = fun.curryN(function(predicates, item)
    for i = 1, #predicates do
        if not predicates[i](item) then
            return false
        end
    end
    return true
end, 2)

---@generic T
---@param predicate fun(item: T): boolean
---@param a fun(item: T): any
---@param b fun(item: T): any
---@param value T
_.if_else = fun.curryN(function(predicate, a, b, value)
    if predicate(value) then
        return a(value)
    else
        return b(value)
    end
end, 4)

---@param value boolean
_.is_not = function(value)
    return not value
end

---@generic T
---@param predicate fun(value: T): boolean
---@param value T
_.complement = fun.curryN(function(predicate, value)
    return not predicate(value)
end, 2)

_.cond = fun.curryN(function(predicate_transformer_pairs, value)
    for _, pair in ipairs(predicate_transformer_pairs) do
        local predicate, transformer = pair[1], pair[2]
        if predicate(value) then
            return transformer(value)
        end
    end
end, 2)

return _
