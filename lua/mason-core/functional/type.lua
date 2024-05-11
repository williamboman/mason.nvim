local fun = require "mason-core.functional.function"
local rel = require "mason-core.functional.relation"

local _ = {}

_.is_nil = rel.equals(nil)

---@param typ type
---@param value any
_.is = fun.curryN(function(typ, value)
    return type(value) == typ
end, 2)

---@param value any
---@return boolean
_.is_list = vim.fn.has "nvim-0.10" and vim.islist or vim.tbl_islist

return _
