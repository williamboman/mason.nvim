local _ = require "nvim-lsp-installer.core.functional"

describe("functional: relation", function()
    it("should check equality", function()
        local tbl = {}
        local is_tbl = _.equals(tbl)
        local is_a = _.equals "a"
        local is_42 = _.equals(42)

        assert.is_true(is_tbl(tbl))
        assert.is_true(is_a "a")
        assert.is_true(is_42(42))
        assert.is_false(is_a "b")
        assert.is_false(is_42(32))
    end)

    it("should check property equality", function()
        local fn_key = function() end
        local tbl = { a = "a", b = "b", number = 42, [fn_key] = "fun" }
        assert.is_true(_.prop_eq("a", "a", tbl))
        assert.is_true(_.prop_eq(fn_key, "fun", tbl))
        assert.is_true(_.prop_eq(fn_key) "fun"(tbl))
    end)

    it("should check whether property satisfies predicate", function()
        local obj = {
            low = 0,
            med = 10,
            high = 15,
        }

        assert.is_false(_.prop_satisfies(_.gt(10), "low", obj))
        assert.is_false(_.prop_satisfies(_.gt(10), "med")(obj))
        assert.is_true(_.prop_satisfies(_.gt(10)) "high"(obj))
    end)
end)
