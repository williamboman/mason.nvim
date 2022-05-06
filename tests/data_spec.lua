local Data = require "nvim-lsp-installer.data"
local spy = require "luassert.spy"
local match = require "luassert.match"

describe("data", function()
    it("creates enums", function()
        local colors = Data.enum {
            "BLUE",
            "YELLOW",
        }
        assert.same({
            ["BLUE"] = "BLUE",
            ["YELLOW"] = "YELLOW",
        }, colors)
    end)

    it("creates sets", function()
        local colors = Data.set_of {
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
        }, Data.list_reverse(colors))
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
            Data.list_map(function(color, i)
                return "LIGHT_" .. color .. i
            end, colors)
        )
        -- should not modify in-place
        assert.same({ "BLUE", "YELLOW", "RED" }, colors)
    end)

    it("coalesces first non-nil value", function()
        assert.equal("Hello World!", Data.coalesce(nil, nil, "Hello World!", ""))
    end)

    it("makes a shallow copy of a list", function()
        local list = { "BLUE", { nested = "TABLE" }, "RED" }
        local list_copy = Data.list_copy(list)
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
            Data.list_find_first({
                "Where",
                "On Earth",
                "Is",
                "Waldo",
                "?",
            }, predicate)
        )
        assert.spy(predicate).was.called(4)
    end)

    it("determines whether any item in the list fulfills predicate", function()
        local predicate = spy.new(function(item)
            return item == "On Earth"
        end)

        assert.is_true(Data.list_any({
            "Where",
            "On Earth",
            "Is",
            "Waldo",
            "?",
        }, predicate))

        assert.spy(predicate).was.called(2)
    end)

    it("memoizes functions with default cache mechanism", function()
        local expensive_function = spy.new(function(s)
            return s
        end)
        local memoized_fn = Data.memoize(expensive_function)
        assert.equal("key", memoized_fn "key")
        assert.equal("key", memoized_fn "key")
        assert.equal("new_key", memoized_fn "new_key")
        assert.spy(expensive_function).was_called(2)
    end)

    it("memoizes function with custom cache mechanism", function()
        local expensive_function = spy.new(function(arg1, arg2)
            return arg1 .. arg2
        end)
        local memoized_fn = Data.memoize(expensive_function, function(arg1, arg2)
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
        local lazy_fn = Data.lazy(impl)
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
end)
