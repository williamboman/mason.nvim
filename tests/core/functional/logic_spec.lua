local spy = require "luassert.spy"
local _ = require "nvim-lsp-installer.core.functional"

describe("functional: logic", function()
    it("should check that all_pass checks that all predicates pass", function()
        local is_waldo = function(i)
            return i == "waldo"
        end
        assert.is_true(_.all_pass { _.T, _.T, is_waldo, _.T } "waldo")
        assert.is_false(_.all_pass { _.T, _.T, is_waldo, _.F } "waldo")
        assert.is_false(_.all_pass { _.T, _.T, is_waldo, _.T } "waldina")
    end)

    it("should branch if_else", function()
        local a = spy.new()
        local b = spy.new()
        _.if_else(_.T, a, b) "a"
        _.if_else(_.F, a, b) "b"
        assert.spy(a).was_called(1)
        assert.spy(a).was_called_with "a"
        assert.spy(b).was_called(1)
        assert.spy(b).was_called_with "b"
    end)

    it("should flip booleans", function()
        assert.is_true(_.is_not(false))
        assert.is_false(_.is_not(true))
    end)

    it("should resolve correct cond", function()
        local planetary_object = _.cond {
            {
                _.equals "Moon!",
                _.format "to the %s",
            },
            {
                _.equals "World!",
                _.format "Hello %s",
            },
        }
        assert.equals("Hello World!", planetary_object "World!")
        assert.equals("to the Moon!", planetary_object "Moon!")
    end)

    it("should give complements", function()
        assert.is_true(_.complement(_.is_nil, "not nil"))
        assert.is_false(_.complement(_.is_nil, nil))
    end)
end)
