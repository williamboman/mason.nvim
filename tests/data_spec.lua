local Data = require "nvim-lsp-installer.data"
local spy = require "luassert.spy"

describe("data", function()
    it("creates enums", function()
        local colors = Data.enum {
            "BLUE",
            "YELLOW",
        }
        assert.equal(
            vim.inspect {
                ["BLUE"] = "BLUE",
                ["YELLOW"] = "YELLOW",
            },
            vim.inspect(colors)
        )
    end)

    it("creates sets", function()
        local colors = Data.set_of {
            "BLUE",
            "YELLOW",
            "BLUE",
            "RED",
        }
        assert.equal(
            vim.inspect {
                ["BLUE"] = true,
                ["YELLOW"] = true,
                ["RED"] = true,
            },
            vim.inspect(colors)
        )
    end)

    it("reverses lists", function()
        local colors = { "BLUE", "YELLOW", "RED" }
        assert.equal(
            vim.inspect {
                "RED",
                "YELLOW",
                "BLUE",
            },
            vim.inspect(Data.list_reverse(colors))
        )
        -- should not modify in-place
        assert.equal(vim.inspect { "BLUE", "YELLOW", "RED" }, vim.inspect(colors))
    end)

    it("maps over list", function()
        local colors = { "BLUE", "YELLOW", "RED" }
        assert.equal(
            vim.inspect {
                "LIGHT_BLUE1",
                "LIGHT_YELLOW2",
                "LIGHT_RED3",
            },
            vim.inspect(Data.list_map(function(color, i)
                return "LIGHT_" .. color .. i
            end, colors))
        )
        -- should not modify in-place
        assert.equal(vim.inspect { "BLUE", "YELLOW", "RED" }, vim.inspect(colors))
    end)

    it("coalesces first non-nil value", function()
        assert.equal("Hello World!", Data.coalesce(nil, nil, "Hello World!", ""))
    end)

    it("makes a shallow copy of a list", function()
        local list = { "BLUE", { nested = "TABLE" }, "RED" }
        local list_copy = Data.list_copy(list)
        assert.equal(vim.inspect { "BLUE", { nested = "TABLE" }, "RED" }, vim.inspect(list_copy))
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
end)
