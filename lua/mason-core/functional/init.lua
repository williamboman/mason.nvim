local _ = {}

local function lazy_require(module)
    return setmetatable({}, {
        __index = function(m, k)
            return function(...)
                return require(module)[k](...)
            end
        end,
    })
end

---@module "mason-core.functional.data"
local data = lazy_require "mason-core.functional.data"
_.table_pack = data.table_pack
_.enum = data.enum
_.set_of = data.set_of

---@module "mason-core.functional.function"
local fun = lazy_require "mason-core.functional.function"
_.curryN = fun.curryN
_.compose = fun.compose
_.partial = fun.partial
_.identity = fun.identity
_.always = fun.always
_.T = fun.T
_.F = fun.F
_.memoize = fun.memoize
_.lazy = fun.lazy
_.tap = fun.tap
_.apply_to = fun.apply_to
_.apply = fun.apply
_.converge = fun.converge
_.apply_spec = fun.apply_spec

---@module "mason-core.functional.list"
local list = lazy_require "mason-core.functional.list"
_.reverse = list.reverse
_.list_not_nil = list.list_not_nil
_.list_copy = list.list_copy
_.find_first = list.find_first
_.any = list.any
_.all = list.all
_.filter = list.filter
_.map = list.map
_.filter_map = list.filter_map
_.each = list.each
_.concat = list.concat
_.append = list.append
_.prepend = list.prepend
_.zip_table = list.zip_table
_.nth = list.nth
_.head = list.head
_.last = list.last
_.length = list.length
_.flatten = list.flatten
_.sort_by = list.sort_by
_.uniq_by = list.uniq_by
_.join = list.join
_.partition = list.partition
_.take = list.take
_.drop = list.drop
_.drop_last = list.drop_last

---@module "mason-core.functional.relation"
local relation = lazy_require "mason-core.functional.relation"
_.equals = relation.equals
_.prop_eq = relation.prop_eq
_.prop_satisfies = relation.prop_satisfies
_.path_satisfies = relation.path_satisfies
_.min = relation.min
_.add = relation.add

---@module "mason-core.functional.logic"
local logic = lazy_require "mason-core.functional.logic"
_.all_pass = logic.all_pass
_.any_pass = logic.any_pass
_.if_else = logic.if_else
_.is_not = logic.is_not
_.complement = logic.complement
_.cond = logic.cond

---@module "mason-core.functional.number"
local number = lazy_require "mason-core.functional.number"
_.negate = number.negate
_.gt = number.gt
_.gte = number.gte
_.lt = number.lt
_.lte = number.lte
_.inc = number.inc
_.dec = number.dec

---@module "mason-core.functional.string"
local string = lazy_require "mason-core.functional.string"
_.matches = string.matches
_.match = string.match
_.format = string.format
_.split = string.split
_.gsub = string.gsub
_.trim = string.trim
_.dedent = string.dedent
_.starts_with = string.starts_with
_.to_upper = string.to_upper
_.to_lower = string.to_lower

---@module "mason-core.functional.table"
local tbl = lazy_require "mason-core.functional.table"
_.prop = tbl.prop
_.path = tbl.path
_.pick = tbl.pick
_.keys = tbl.keys
_.size = tbl.size
_.to_pairs = tbl.to_pairs
_.from_pairs = tbl.from_pairs
_.invert = tbl.invert
_.evolve = tbl.evolve
_.merge_left = tbl.merge_left
_.dissoc = tbl.dissoc

---@module "mason-core.functional.type"
local typ = lazy_require "mason-core.functional.type"
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
