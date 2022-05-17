local fun = require "nvim-lsp-installer.core.functional.function"

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

return _
