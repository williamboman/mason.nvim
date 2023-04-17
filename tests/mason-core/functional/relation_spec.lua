local _ = require "mason-core.functional"

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

    it("should check non-equality", function()
        local tbl = {}
        local is_not_tbl = _.not_equals(tbl)
        local is_not_a = _.not_equals "a"
        local is_not_42 = _.not_equals(42)

        assert.is_false(is_not_tbl(tbl))
        assert.is_false(is_not_a "a")
        assert.is_false(is_not_42(42))
        assert.is_true(is_not_a "b")
        assert.is_true(is_not_42(32))
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

    it("should check whether nested property satisfies predicate", function()
        local obj = {
            low = { value = 0 },
            med = { value = 10 },
            high = { value = 15 },
        }

        assert.is_false(_.path_satisfies(_.gt(10), { "low", "value" }, obj))
        assert.is_false(_.path_satisfies(_.gt(10), { "med", "value" })(obj))
        assert.is_true(_.path_satisfies(_.gt(10)) { "high", "value" }(obj))
    end)

    it("should subtract numbers", function()
        assert.equals(42, _.min(42, 84))
        assert.equals(-1, _.min(11, 10))
    end)

    it("should add numbers", function()
        assert.equals(1337, _.add(1300, 37))
        assert.equals(-10, _.add(90, -100))
    end)
end)
