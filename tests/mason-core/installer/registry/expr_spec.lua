local match = require "luassert.match"
local expr = require "mason-core.installer.registry.expr"
local Result = require "mason-core.result"

describe("registry expressions", function()
    it("should eval simple expressions", function()
        assert.same(Result.success "Hello, world!", expr.interpolate("Hello, world!", {}))

        assert.same(
            Result.success "Hello, John Doe!",
            expr.interpolate("Hello, {{firstname}} {{ lastname   }}!", {
                firstname = "John",
                lastname = "Doe",
            })
        )
    end)

    it("should eval nested access", function()
        assert.same(
            Result.success "Hello, world!",
            expr.interpolate("Hello, {{greeting.name}}!", { greeting = { name = "world" } })
        )
    end)

    it("should eval benign expressions", function()
        assert.same(
            Result.success "Hello, JOHNDOE JR.!",
            expr.interpolate("Hello, {{greeting.firstname .. greeting.lastname .. tostring(tbl) | to_upper}}!", {
                greeting = { firstname = "John", lastname = "Doe" },
                tbl = setmetatable({}, {
                    __tostring = function()
                        return " Jr."
                    end,
                }),
            })
        )

        assert.same(
            Result.success "Gloves",
            expr.interpolate("G{{ 'Cloves' | strip_prefix(trim) }}", {
                trim = "C",
            })
        )
    end)

    it("should eval expressions with filters", function()
        assert.same(
            Result.success "Hello, MR. John!",
            expr.interpolate("Hello, {{prefix|to_upper}} {{  name | trim   }}!", {
                prefix = "Mr.",
                name = " John   ",
            })
        )

        assert.same(
            Result.success "Hello, Sir MR. John!",
            expr.interpolate("Hello, {{prefix|to_upper | format 'Sir %s'}} {{  name | trim   }}!", {
                prefix = "Mr.",
                name = " John   ",
            })
        )
    end)

    it("should not interpolate nil values", function()
        assert.same(Result.success "Hello, ", expr.interpolate("Hello, {{non_existent}}", {}))
        assert.same(Result.success "", expr.interpolate("{{non_existent}}", {}))
    end)

    it("should error if piping nil values to functions that require non-nil values", function()
        local err = assert.has_error(function()
            expr.interpolate("Hello, {{ non_existent | to_upper }}", {}):get_or_throw()
        end)
        assert.is_true(match.matches "attempt to index local 'str' %(a nil value%)$"(err))
    end)

    it("should reject invalid filters", function()
        assert.is_true(
            match.matches [[^.*Invalid filter expression: "whut"]](
                expr.interpolate("Hello, {{ value | whut }}", { value = "value" }):err_or_nil()
            )
        )
        assert.is_true(
            match.matches [[^.*Failed to parse expression: "wh%-!uut"]](
                expr.interpolate("Hello, {{ value | wh-!uut }}", { value = "value" }):err_or_nil()
            )
        )
    end)
end)

describe("table interpolation", function()
    it("should interpolate nested values", function()
        assert.same(
            Result.success {
                some = {
                    nested = {
                        value = "here",
                    },
                },
            },
            expr.tbl_interpolate({
                some = {
                    nested = {
                        value = "{{value}}",
                    },
                },
            }, { value = "here" })
        )
    end)

    it("should only only interpolate string values", function()
        assert.same(
            Result.success {
                a = 1,
                b = { c = 2 },
                d = "Hello!",
            },
            expr.tbl_interpolate({
                a = 1,
                b = { c = 2 },
                d = "Hello!",
            }, {})
        )
    end)
end)
