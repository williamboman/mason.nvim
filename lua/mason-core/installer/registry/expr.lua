local Result = require "mason-core.result"
local _ = require "mason-core.functional"

local M = {}

local parse_expr = _.compose(
    _.apply_spec {
        value_expr = _.head,
        filters = _.drop(1),
    },
    _.filter(_.complement(_.equals "")),
    _.map(_.trim),
    _.split "|"
)

local FILTERS = {
    format = _.format,
    gsub = _.gsub,
    to_lower = _.to_lower,
    to_upper = _.to_upper,
    trim = _.trim,
    trim_start = _.trim_start,
    trim_end = _.trim_end,
    strip_prefix = _.strip_prefix,
    strip_suffix = _.strip_suffix,
    tostring = tostring,
}

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

---@param expr string
---@param ctx table<string, any>
local function eval(expr, ctx)
    return setfenv(assert(loadstring("return " .. expr), ("Failed to parse expression: %q"):format(expr)), ctx)()
end

---@param str string
---@param ctx table<string, any>
function M.interpolate(str, ctx)
    ctx = shallow_clone(ctx)
    setmetatable(ctx, { __index = FILTERS })
    return Result.pcall(function()
        return _.gsub("{{([^}]+)}}", function(expr)
            local components = parse_expr(expr)

            local value = eval(components.value_expr, ctx)

            local filters = _.map(function(filter_expr)
                local filter = eval(filter_expr, ctx)
                assert(type(filter) == "function", ("Invalid filter expression: %q"):format(filter_expr))
                return filter
            end, components.filters)

            return _.reduce(_.apply_to, value, filters) or ""
        end, str)
    end)
end

---@generic T : table
---@param tbl T
---@param ctx table
---@return T
function M.tbl_interpolate(tbl, ctx)
    return Result.try(function(try)
        local interpolated = {}
        for k, v in pairs(tbl) do
            if type(v) == "string" then
                interpolated[k] = try(M.interpolate(v, ctx))
            elseif type(v) == "table" then
                interpolated[k] = try(M.tbl_interpolate(v, ctx))
            else
                interpolated[k] = v
            end
        end
        return interpolated
    end)
end

return M
