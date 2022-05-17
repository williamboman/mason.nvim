local spy = require "luassert.spy"
local match = require "luassert.match"
local _ = require "nvim-lsp-installer.core.functional"

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
        assert.equal("Hello World!", _.coalesce(nil, nil, "Hello World!", ""))
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
        local e = assert.error(function()
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
        assert.equal("key", memoized_fn "key")
        assert.equal("key", memoized_fn "key")
        assert.equal("new_key", memoized_fn "new_key")
        assert.spy(expensive_function).was_called(2)
    end)

    it("memoizes function with custom cache mechanism", function()
        local expensive_function = spy.new(function(arg1, arg2)
            return arg1 .. arg2
        end)
        local memoized_fn = _.memoize(expensive_function, function(arg1, arg2)
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
        assert.equal(2, b)
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
end)
