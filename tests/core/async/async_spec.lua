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
            local success, exit_code = a.promisify(process.spawn)("env", {
                args = {},
                env = { "FOO=BAR", "BAR=BAZ" },
                stdio_sink = stdio.sink,
            })
            assert.is_true(success)
            assert.equals(0, exit_code)
            assert.equals("FOO=BAR\nBAR=BAZ\n", table.concat(stdio.buffers.stdout, ""))
        end)
    )

    it(
        "should return all values",
        async_test(function()
            local val1, val2, val3 = a.wait(function(resolve)
                resolve(1, 2, 3)
            end)
            assert.equals(1, val1)
            assert.equals(2, val2)
            assert.equals(3, val3)
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
        "should raise error if async function raises error",
        async_test(function()
            local err = assert.has.errors(a.promisify(function()
                error "something went wrong"
            end))
            assert.is_true(match.has_match "something went wrong$"(err))
        end)
    )

    it(
        "should raise error if async function rejects",
        async_test(function()
            local err = assert.has.errors(function()
                a.wait(function(_, reject)
                    reject "This is an error"
                end)
            end)
            assert.equals("This is an error", err)
        end)
    )

    it(
        "should pass nil arguments to promisified functions",
        async_test(function()
            local fn = spy.new(function(_, _, _, _, _, _, _, cb)
                cb()
            end)
            a.promisify(fn)(nil, 2, nil, 4, nil, nil, 7)
            assert.spy(fn).was_called_with(nil, 2, nil, 4, nil, nil, 7, match.is_function())
        end)
    )
end)
