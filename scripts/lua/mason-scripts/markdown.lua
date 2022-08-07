local path = require "mason-core.path"
local _ = require "mason-core.functional"
local script_utils = require "mason-scripts.utils"
local fs = require "mason-core.fs"

local M = {}

---Direct context access syntax (e.g. "{{ value }}" or "{{ nested.value }}")
---@param context table<string, any>
---@param str string
local prop_interpolate = _.curryN(function(context, str)
    return _.gsub("{{%s?([%w_%.0-9]+)%s?}}", function(key)
        return vim.tbl_get(context, unpack(_.split("%.", key)))
    end, str)
end, 2)

local TEMPLATE_GLOBALS = {
    _ = _,
    url = function(url)
        return ("[%s](%s)"):format(url, url)
    end,
    link = function(heading)
        -- TODO turn heading into valid string, not needed for now
        return ("[%s](#%s)"):format(heading, heading)
    end,
    wrap = _.curryN(function(wrap, str)
        return ("%s%s%s"):format(wrap, str, wrap)
    end, 2),
    list = _.compose(_.join "\n", _.map(_.format "- %s")),
    join = _.curryN(function(items, delim)
        return _.join(delim, items)
    end, 2),
    each = _.curryN(function(items, format)
        local formatter = _.cond {
            { _.is "function", _.identity },
            {
                _.is "string",
                function(template)
                    return function(item)
                        return prop_interpolate({ it = item }, template)
                    end
                end,
            },
        }(format)
        return _.map(formatter, items)
    end, 2),
    render_each = _.curryN(function(items, template_file)
        return _.map(M.render(template_file), items)
    end, 2),
}

---Expression syntax (e.g. "{% "hello world" %}" or "{% join({"One", "Two"}), "\n" %}")
---@param context table<string, any>
---@param str string
local expr_interpolate = _.curryN(function(context, str)
    return _.gsub(
        [[{%%%s?([%w%-_%.0-9%(%)%[%]%s%+%*,"/\|=%{%}`]+)%s?%%}]], -- giggity
        function(expr)
            local eval_result =
                setfenv(loadstring(("return %s"):format(expr)), setmetatable(TEMPLATE_GLOBALS, { __index = context }))()

            if type(eval_result) == "table" then
                -- expressions may return tables for convenience reasons
                return _.join("", eval_result)
            else
                return eval_result
            end
        end,
        str
    )
end, 2)

local header_interpolate = _.curryN(function(context, str)
    return _.gsub([[{#%s?([%w%s_%-%.0-9/"]+)%s?#}]], function(header)
        setfenv(loadstring(header), {
            include = function(file)
                local mod = require(("mason-scripts.templates.%s"):format(file))
                for k, v in pairs(mod) do
                    context[k] = v
                end
            end,
        })()
        return ""
    end, str)
end, 2)

---@param template_file string
---@param context table<string, string>
M.render = _.curryN(function(template_file, context)
    local template = fs.sync.read_file(script_utils.rel_path(path.concat { "templates", template_file }))
    local interpolate = _.compose(prop_interpolate(context), expr_interpolate(context), header_interpolate(context))
    local formatted_template = interpolate(template)
    return formatted_template
end, 2)

return M
