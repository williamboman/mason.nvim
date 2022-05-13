local functional = require "nvim-lsp-installer.core.functional"
local spy = require "luassert.spy"
local match = require "luassert.match"

describe("functional", function()
    it("creates enums", function()
        local colors = functional.enum {
            "BLUE",
            "YELLOW",
        }
        assert.same({
            ["BLUE"] = "BLUE",
            ["YELLOW"] = "YELLOW",
        }, colors)
    end)

    it("creates sets", function()
        local colors = functional.set_of {
            "BLUE",
            "YELLOW",
            "BLUE",
            "RED",
        }
        assert.same({
            ["BLUE"] = true,
            ["YELLOW"] = true,
            ["RED"] = true,
        }, colors)
    end)

    it("reverses lists", function()
        local colors = { "BLUE", "YELLOW", "RED" }
        assert.same({
            "RED",
            "YELLOW",
            "BLUE",
        }, functional.list_reverse(colors))
        -- should not modify in-place
        assert.same({ "BLUE", "YELLOW", "RED" }, colors)
    end)

    it("maps over list", function()
        local colors = { "BLUE", "YELLOW", "RED" }
        assert.same(
            {
                "LIGHT_BLUE1",
                "LIGHT_YELLOW2",
                "LIGHT_RED3",
            },
            functional.list_map(function(color, i)
                return "LIGHT_" .. color .. i
            end, colors)
        )
        -- should not modify in-place
        assert.same({ "BLUE", "YELLOW", "RED" }, colors)
    end)

    it("coalesces first non-nil value", function()
        assert.equal("Hello World!", functional.coalesce(nil, nil, "Hello World!", ""))
    end)

    it("makes a shallow copy of a list", function()
        local list = { "BLUE", { nested = "TABLE" }, "RED" }
        local list_copy = functional.list_copy(list)
        assert.same({ "BLUE", { nested = "TABLE" }, "RED" }, list_copy)
        assert.is_not.is_true(list == list_copy)
        assert.is_true(list[2] == list_copy[2])
    end)

    it("finds first item that fulfills predicate", function()
        local predicate = spy.new(function(item)
            return item == "Waldo"
        end)

        assert.equal(
            "Waldo",
            functional.list_find_first(predicate, {
                "Where",
                "On Earth",
                "Is",
                "Waldo",
                "?",
            })
        )
        assert.spy(predicate).was.called(4)
    end)

    it("determines whether any item in the list fulfills predicate", function()
        local predicate = spy.new(function(item)
            return item == "On Earth"
        end)

        assert.is_true(functional.list_any(predicate, {
            "Where",
            "On Earth",
            "Is",
            "Waldo",
            "?",
        }))

        assert.spy(predicate).was.called(2)
    end)

    it("memoizes functions with default cache mechanism", function()
        local expensive_function = spy.new(function(s)
            return s
        end)
        local memoized_fn = functional.memoize(expensive_function)
        assert.equal("key", memoized_fn "key")
        assert.equal("key", memoized_fn "key")
        assert.equal("new_key", memoized_fn "new_key")
        assert.spy(expensive_function).was_called(2)
    end)

    it("memoizes function with custom cache mechanism", function()
        local expensive_function = spy.new(function(arg1, arg2)
            return arg1 .. arg2
        end)
        local memoized_fn = functional.memoize(expensive_function, function(arg1, arg2)
            return arg1 .. arg2
        end)
        assert.equal("key1key2", memoized_fn("key1", "key2"))
        assert.equal("key1key2", memoized_fn("key1", "key2"))
        assert.equal("key1key3", memoized_fn("key1", "key3"))
        assert.spy(expensive_function).was_called(2)
    end)

    it("should evaluate functions lazily", function()
        local impl = spy.new(function()
            return {}, {}
        end)
        local lazy_fn = functional.lazy(impl)
        assert.spy(impl).was_called(0)
        local a, b = lazy_fn()
        assert.spy(impl).was_called(1)
        assert.is_true(match.is_table()(a))
        assert.is_true(match.is_table()(b))
        local new_a, new_b = lazy_fn()
        assert.spy(impl).was_called(1)
        assert.is_true(match.is_ref(a)(new_a))
        assert.is_true(match.is_ref(b)(new_b))
    end)

    it("should support nil return values in lazy functions", function()
        local lazy_fn = functional.lazy(function()
            return nil, 2
        end)
        local a, b = lazy_fn()
        assert.is_nil(a)
        assert.equal(2, b)
    end)

    it("should partially apply functions", function()
        local funcy = spy.new()
        local partially_funcy = functional.partial(funcy, "a", "b", "c")
        partially_funcy("d", "e", "f")
        assert.spy(funcy).was_called_with("a", "b", "c", "d", "e", "f")
    end)

    it("should partially apply functions with nil arguments", function()
        local funcy = spy.new()
        local partially_funcy = functional.partial(funcy, "a", nil, "c")
        partially_funcy("d", nil, "f")
        assert.spy(funcy).was_called_with("a", nil, "c", "d", nil, "f")
    end)

    it("should compose functions", function()
        local function add(x)
            return function(y)
                return y + x
            end
        end
        local function subtract(x)
            return function(y)
                return y - x
            end
        end
        local function multiply(x)
            return function(y)
                return y * x
            end
        end

        local big_maths = functional.compose(add(1), subtract(3), multiply(5))

        assert.equals(23, big_maths(5))
    end)

    it("should not allow composing no functions", function()
        local e = assert.error(function()
            functional.compose()
        end)
        assert.equals("compose requires at least one function", e)
    end)

    it("should iterate list in .each", function()
        local list = { "BLUE", "YELLOW", "RED" }
        local iterate_fn = spy.new()
        functional.each(iterate_fn, list)
        assert.spy(iterate_fn).was_called(3)
        assert.spy(iterate_fn).was_called_with("BLUE", 1)
        assert.spy(iterate_fn).was_called_with("YELLOW", 2)
        assert.spy(iterate_fn).was_called_with("RED", 3)
    end)

    it("should negate predicates", function()
        local predicate = spy.new(function(item)
            return item == "Waldo"
        end)
        local negated_predicate = functional.negate(predicate)
        assert.is_false(negated_predicate "Waldo")
        assert.is_true(negated_predicate "Where")
        assert.spy(predicate).was_called(2)
    end)

    it("should check that all_pass checks that all predicates pass", function()
        local t = functional.always(true)
        local f = functional.always(false)
        local is_waldo = function(i)
            return i == "waldo"
        end
        assert.is_true(functional.all_pass { t, t, is_waldo, t } "waldo")
        assert.is_false(functional.all_pass { t, t, is_waldo, f } "waldo")
        assert.is_false(functional.all_pass { t, t, is_waldo, t } "waldina")
    end)

    it("should index object by prop", function()
        local waldo = functional.prop "where is he"
        assert.equals("nowhere to be found", waldo { ["where is he"] = "nowhere to be found" })
    end)

    it("should branch if_else", function()
        local a = spy.new()
        local b = spy.new()
        functional.if_else(functional.T, a, b)("a", 1)
        functional.if_else(functional.F, a, b)("b", 2)
        assert.spy(a).was_called(1)
        assert.spy(a).was_called_with("a", 1)
        assert.spy(b).was_called(1)
        assert.spy(b).was_called_with("b", 2)
    end)

    it("should check if string matches", function()
        assert.is_false(functional.matches "a" "b")
        assert.is_true(functional.matches "a" "a")
    end)
end)
