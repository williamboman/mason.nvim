local match = require "luassert.match"
local expr = require "mason-core.installer.registry.expr"
local Result = require "mason-core.result"

describe("registry expressions", function()
    it("should eval simple expressions", function()
        assert.same(Result.success "Hello, world!", expr.eval "Hello, world!")

        assert.same(
            Result.success "Hello, John Doe!",
            expr.eval("Hello, {{firstname}} {{ lastname   }}!", {
                firstname = "John",
                lastname = "Doe",
            })
        )
    end)

    it("should eval expressions with filters", function()
        assert.same(
            Result.success "Hello, MR. John!",
            expr.eval("Hello, {{prefix|to_upper}} {{  name | trim   }}!", {
                prefix = "Mr.",
                name = " John   ",
            })
        )

        assert.same(
            Result.success "Hello, Sir MR. John!",
            expr.eval("Hello, {{prefix|to_upper | format 'Sir %s'}} {{  name | trim   }}!", {
                prefix = "Mr.",
                name = " John   ",
            })
        )
    end)

    it("should reject invalid values", function()
        assert.is_true(
            match.matches [[^.*Unable to interpolate value: "non_existent"%.$]](
                expr.eval("Hello, {{non_existent}}", {}):err_or_nil()
            )
        )
    end)

    it("should reject invalid filters", function()
        assert.is_true(
            match.matches [[^.*Invalid filter expression: "whut"%.$]](
                expr.eval("Hello, {{ value | whut }}", { value = "value" }):err_or_nil()
            )
        )

        assert.is_true(
            match.matches [[^.*Failed to parse filter: "wh%-!uut"%.$]](
                expr.eval("Hello, {{ value | wh-!uut }}", { value = "value" }):err_or_nil()
            )
        )
    end)
end)
