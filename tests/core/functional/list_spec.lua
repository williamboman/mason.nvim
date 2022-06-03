local spy = require "luassert.spy"
local _ = require "nvim-lsp-installer.core.functional"

describe("functional: list", function()
    it("should produce list without nils", function()
        assert.same({ 1, 2, 3, 4 }, _.list_not_nil(nil, 1, 2, nil, 3, nil, 4, nil))
    end)

    it("makes a shallow copy of a list", function()
        local list = { "BLUE", { nested = "TABLE" }, "RED" }
        local list_copy = _.list_copy(list)
        assert.same({ "BLUE", { nested = "TABLE" }, "RED" }, list_copy)
        assert.is_not.is_true(list == list_copy)
        assert.is_true(list[2] == list_copy[2])
    end)

    it("reverses lists", function()
        local colors = { "BLUE", "YELLOW", "RED" }
        assert.same({
            "RED",
            "YELLOW",
            "BLUE",
        }, _.reverse(colors))
        -- should not modify in-place
        assert.same({ "BLUE", "YELLOW", "RED" }, colors)
    end)

    it("maps over list", function()
        local colors = { "BLUE", "YELLOW", "RED" }
        assert.same(
            {
                "LIGHT_BLUE",
                "LIGHT_YELLOW",
                "LIGHT_RED",
            },
            _.map(function(color)
                return "LIGHT_" .. color
            end, colors)
        )
        -- should not modify in-place
        assert.same({ "BLUE", "YELLOW", "RED" }, colors)
    end)

    it("finds first item that fulfills predicate", function()
        local predicate = spy.new(function(item)
            return item == "Waldo"
        end)

        assert.equal(
            "Waldo",
            _.find_first(predicate, {
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

        assert.is_true(_.any(predicate, {
            "Where",
            "On Earth",
            "Is",
            "Waldo",
            "?",
        }))

        assert.spy(predicate).was.called(2)
    end)

    it("should iterate list in .each", function()
        local list = { "BLUE", "YELLOW", "RED" }
        local iterate_fn = spy.new()
        _.each(iterate_fn, list)
        assert.spy(iterate_fn).was_called(3)
        assert.spy(iterate_fn).was_called_with("BLUE", 1)
        assert.spy(iterate_fn).was_called_with("YELLOW", 2)
        assert.spy(iterate_fn).was_called_with("RED", 3)
    end)

    it("should concat list tables", function()
        local list = { "monstera", "tulipa", "carnation" }
        assert.same({ "monstera", "tulipa", "carnation", "rose", "daisy" }, _.concat(list, { "rose", "daisy" }))
        assert.same({ "monstera", "tulipa", "carnation" }, list) -- does not mutate list
    end)

    it("should concat strings", function()
        assert.equals("FooBar", _.concat("Foo", "Bar"))
    end)

    it("should zip list into table", function()
        local fnkey = function() end
        assert.same({
            a = "a",
            [fnkey] = 1,
        }, _.zip_table({ "a", fnkey }, { "a", 1 }))
    end)

    it("should get nth item", function()
        assert.equals("first", _.nth(1, { "first", "middle", "last" }))
        assert.equals("last", _.nth(-1, { "first", "middle", "last" }))
        assert.equals("middle", _.nth(-2, { "first", "middle", "last" }))
        assert.equals("a", _.nth(1, "abc"))
        assert.equals("c", _.nth(-1, "abc"))
        assert.equals("b", _.nth(-2, "abc"))
        assert.is_nil(_.nth(0, { "value" }))
        assert.equals("", _.nth(0, "abc"))
    end)

    it("should get length", function()
        assert.equals(0, _.length {})
        assert.equals(0, _.length { nil })
        assert.equals(0, _.length { obj = "doesnt count" })
        assert.equals(0, _.length "")
        assert.equals(1, _.length { "" })
        assert.equals(4, _.length "fire")
    end)
end)
