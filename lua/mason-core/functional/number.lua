local fun = require "mason-core.functional.function"

local _ = {}

---@param number number
_.negate = function(number)
    return -number
end

_.gt = fun.curryN(function(number, value)
    return value > number
end, 2)

_.gte = fun.curryN(function(number, value)
    return value >= number
end, 2)

_.lt = fun.curryN(function(number, value)
    return value < number
end, 2)

_.lte = fun.curryN(function(number, value)
    return value <= number
end, 2)

_.inc = fun.curryN(function(increment, value)
    return value + increment
end, 2)

_.dec = fun.curryN(function(decrement, value)
    return value - decrement
end, 2)

return _
