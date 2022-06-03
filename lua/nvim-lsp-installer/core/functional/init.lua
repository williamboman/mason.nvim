local _ = {}

-- data
local data = require "nvim-lsp-installer.core.functional.data"
_.table_pack = data.table_pack
_.enum = data.enum
_.set_of = data.set_of

-- function
local fun = require "nvim-lsp-installer.core.functional.function"
_.curryN = fun.curryN
_.compose = fun.compose
_.partial = fun.partial
_.identity = fun.identity
_.always = fun.always
_.T = fun.T
_.F = fun.F
_.memoize = fun.memoize
_.lazy = fun.lazy

-- list
local list = require "nvim-lsp-installer.core.functional.list"
_.reverse = list.reverse
_.list_not_nil = list.list_not_nil
_.list_copy = list.list_copy
_.find_first = list.find_first
_.any = list.any
_.filter = list.filter
_.map = list.map
_.each = list.each
_.concat = list.concat
_.zip_table = list.zip_table
_.nth = list.nth
_.head = list.head
_.length = list.length

-- relation
local relation = require "nvim-lsp-installer.core.functional.relation"
_.equals = relation.equals
_.prop_eq = relation.prop_eq
_.prop_satisfies = relation.prop_satisfies

-- logic
local logic = require "nvim-lsp-installer.core.functional.logic"
_.all_pass = logic.all_pass
_.if_else = logic.if_else
_.is_not = logic.is_not
_.complement = logic.complement
_.cond = logic.cond

-- number
local number = require "nvim-lsp-installer.core.functional.number"
_.negate = number.negate
_.gt = number.gt
_.gte = number.gte
_.lt = number.lt
_.lte = number.lte
_.inc = number.inc
_.dec = number.dec

-- string
local string = require "nvim-lsp-installer.core.functional.string"
_.matches = string.matches
_.format = string.format
_.split = string.split
_.gsub = string.gsub

-- table
local tbl = require "nvim-lsp-installer.core.functional.table"
_.prop = tbl.prop

-- type
local typ = require "nvim-lsp-installer.core.functional.type"
_.is_nil = typ.is_nil
_.is = typ.is

-- TODO do something else with these

_.coalesce = function(...)
    local args = _.table_pack(...)
    for i = 1, args.n do
        local variable = args[i]
        if variable ~= nil then
            return variable
        end
    end
end

_.when = function(condition, value)
    return condition and value or nil
end

_.lazy_when = function(condition, value)
    return condition and value() or nil
end

return _
