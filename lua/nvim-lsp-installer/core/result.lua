---@class Failure
---@field error any
local Failure = {}
Failure.__index = Failure

function Failure.new(error)
    return setmetatable({ error = error }, Failure)
end

---@class Result
---@field value any
local Result = {}
Result.__index = Result

function Result.new(value)
    return setmetatable({
        value = value,
    }, Result)
end

function Result.success(value)
    return Result.new(value)
end

function Result.failure(error)
    return Result.new(Failure.new(error))
end

function Result:get_or_nil()
    if self:is_success() then
        return self.value
    end
end

function Result:err_or_nil()
    if self:is_failure() then
        return self.value.error
    end
end

function Result:is_failure()
    return getmetatable(self.value) == Failure
end

function Result:is_success()
    return getmetatable(self.value) ~= Failure
end

return Result
