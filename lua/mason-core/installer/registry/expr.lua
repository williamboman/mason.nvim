local _ = require "mason-core.functional"
local string_funs = require "mason-core.functional.string"
local Result = require "mason-core.result"

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

---@param str string
---@param ctx table<string, any>
function M.eval(str, ctx)
    return Result.pcall(function()
        return _.gsub("{{([^}]+)}}", function(expr)
            local components = parse_expr(expr)
            local value =
                assert(ctx[components.value_expr], ("Unable to interpolate value: %q."):format(components.value_expr))
            return _.reduce(
                _.apply_to,
                value,
                _.map(function(filter_expr)
                    local filter = setfenv(
                        assert(
                            loadstring("return " .. filter_expr),
                            ("Failed to parse filter: %q."):format(filter_expr)
                        ),
                        string_funs
                    )()
                    assert(type(filter) == "function", ("Invalid filter expression: %q."):format(filter_expr))
                    return filter
                end, components.filters)
            )
        end, str)
    end)
end

return M
