local assert = require "luassert"
local spy = require "luassert.spy"
local match = require "luassert.match"
local a = require "nvim-lsp-installer.core.async"
local process = require "nvim-lsp-installer.process"

local function timestamp()
    local seconds, microseconds = vim.loop.gettimeofday()
    return (seconds * 1000) + math.floor(microseconds / 1000)
end

describe("async", function()
    it("should run in blocking mode", function()
        local start = timestamp()
        a.run_blocking(function()
            a.sleep(1000)
        end)
        local stop = timestamp()
        local grace_ms = 25
        assert.is_true((stop - start) >= (1000 - grace_ms))
    end)

    it(
        "should wrap callback-style async functions",
        async_test(function()
            local stdio = process.in_memory_sink()
            local ok, success = a.promisify(process.spawn)("env", {
                args = {},
                env = { "FOO=BAR", "BAR=BAZ" },
                stdio_sink = stdio.sink,
            })
            assert.is_true(ok)
            assert.is_true(success)
            assert.equals("FOO=BAR\nBAR=BAZ\n", table.concat(stdio.buffers.stdout, ""))
        end)
    )

    it(
        "should cancel coroutine",
        async_test(function()
            local james_bond = spy.new()
            local poutine = a.scope(function()
                a.sleep(100)
                james_bond()
            end)()
            poutine()
            a.sleep(200)
            assert.spy(james_bond).was_not.called()
        end)
    )

    it(
        "should reject if async function raises error",
        async_test(function()
            local ok, err = a.promisify(function()
                error "something went wrong"
            end)()
            assert.is_false(ok)
            assert.is_true(match.has_match "something went wrong$"(err))
        end)
    )
end)
