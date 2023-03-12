local _ = require "mason-core.functional"
local match = require "luassert.match"
local spy = require "luassert.spy"

describe("functional: function", function()
    it("curries functions", function()
        local function sum(...)
            local res = 0
            for i = 1, select("#", ...) do
                res = res + select(i, ...)
            end
            return res
        end
        local arity0 = _.curryN(sum, 0)
        local arity1 = _.curryN(sum, 1)
        local arity2 = _.curryN(sum, 2)
        local arity3 = _.curryN(sum, 3)

        assert.equals(0, arity0(42))
        assert.equals(42, arity1(42))
        assert.equals(3, arity2(1)(2))
        assert.equals(3, arity2(1, 2))
        assert.equals(6, arity3(1)(2)(3))
        assert.equals(6, arity3(1, 2, 3))

        -- should discard superfluous args
        assert.equals(0, arity1(0, 10, 20, 30))
    end)

    it("coalesces first non-nil value", function()
        assert.equals("Hello World!", _.coalesce(nil, nil, "Hello World!", ""))
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

        local big_maths = _.compose(add(1), subtract(3), multiply(5))

        assert.equals(23, big_maths(5))
    end)

    it("should not allow composing no functions", function()
        local e = assert.has_error(function()
            _.compose()
        end)
        assert.equals("compose requires at least one function", e)
    end)

    it("should partially apply functions", function()
        local funcy = spy.new()
        local partially_funcy = _.partial(funcy, "a", "b", "c")
        partially_funcy("d", "e", "f")
        assert.spy(funcy).was_called_with("a", "b", "c", "d", "e", "f")
    end)

    it("should partially apply functions with nil arguments", function()
        local funcy = spy.new()
        local partially_funcy = _.partial(funcy, "a", nil, "c")
        partially_funcy("d", nil, "f")
        assert.spy(funcy).was_called_with("a", nil, "c", "d", nil, "f")
    end)

    it("memoizes functions with default cache mechanism", function()
        local expensive_function = spy.new(function(s)
            return s
        end)
        local memoized_fn = _.memoize(expensive_function)
        assert.equals("key", memoized_fn "key")
        assert.equals("key", memoized_fn "key")
        assert.equals("new_key", memoized_fn "new_key")
        assert.spy(expensive_function).was_called(2)
    end)

    it("memoizes function with custom cache mechanism", function()
        local expensive_function = spy.new(function(arg1, arg2)
            return arg1 .. arg2
        end)
        local memoized_fn = _.memoize(expensive_function, function(arg1, arg2)
            return arg1 .. arg2
        end)
        assert.equals("key1key2", memoized_fn("key1", "key2"))
        assert.equals("key1key2", memoized_fn("key1", "key2"))
        assert.equals("key1key3", memoized_fn("key1", "key3"))
        assert.spy(expensive_function).was_called(2)
    end)

    it("should evaluate functions lazily", function()
        local impl = spy.new(function()
            return {}, {}
        end)
        local lazy_fn = _.lazy(impl)
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
        local lazy_fn = _.lazy(function()
            return nil, 2
        end)
        local a, b = lazy_fn()
        assert.is_nil(a)
        assert.equals(2, b)
    end)

    it("should provide identity value", function()
        local obj = {}
        assert.equals(2, _.identity(2))
        assert.equals(obj, _.identity(obj))
    end)

    it("should always return bound value", function()
        local obj = {}
        assert.equals(2, _.always(2)())
        assert.equals(obj, _.always(obj)())
    end)

    it("true is true and false is false", function()
        assert.is_true(_.T())
        assert.is_false(_.F())
    end)

    it("should tap values", function()
        local fn = spy.new()
        assert.equals(42, _.tap(fn, 42))
        assert.spy(fn).was_called()
        assert.spy(fn).was_called_with(42)
    end)

    it("should apply function", function()
        local max = spy.new(math.max)
        local max_fn = _.apply(max)
        assert.equals(42, max_fn { 1, 2, 3, 4, 5, 6, 7, 8, 9, 42, 10, 8, 4 })
        assert.spy(max).was_called(1)
        assert.spy(max).was_called_with(1, 2, 3, 4, 5, 6, 7, 8, 9, 42, 10, 8, 4)
    end)

    it("should apply value to function", function()
        local agent = spy.new()
        _.apply_to("007", agent)
        assert.spy(agent).was_called(1)
        assert.spy(agent).was_called_with "007"
    end)

    it("should converge on function", function()
        local target = spy.new()
        _.converge(target, { _.head, _.last }, { "These", "Are", "Some", "Words", "Ain't", "That", "Pretty", "Nuts" })
        assert.spy(target).was_called(1)
        assert.spy(target).was_called_with("These", "Nuts")
    end)

    it("should apply spec", function()
        local apply = _.apply_spec {
            sum = _.add(2),
            list = { _.add(2), _.add(6) },
            nested = {
                sum = _.min(2),
            },
        }
        assert.same({
            sum = 4,
            list = { 4, 8 },
            nested = {
                sum = 0,
            },
        }, apply(2))
    end)
end)
