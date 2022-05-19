local assert = require "luassert"
local spy = require "luassert.spy"
local match = require "luassert.match"
local a = require "nvim-lsp-installer.core.async"
local process = require "nvim-lsp-installer.core.process"

local function timestamp()
    local seconds, microseconds = vim.loop.gettimeofday()
    return (seconds * 1000) + math.floor(microseconds / 1000)
end

describe("async", function()
    it("should run in blocking mode", function()
        local start = timestamp()
        a.run_blocking(function()
            a.sleep(100)
        end)
        local stop = timestamp()
        local grace_ms = 50
        assert.is_true((stop - start) >= (100 - grace_ms))
    end)

    it("should return values in blocking mode", function()
        local function slow_maths(arg1, arg2)
            a.sleep(10)
            return arg1 + arg2 - 42
        end
        local value = a.run_blocking(slow_maths, 13, 37)
        assert.equals(8, value)
    end)

    it(
        "should pass arguments to .run",
        async_test(function()
            local callback = spy.new()
            local start = timestamp()
            a.run(a.sleep, callback, 100)
            assert.wait_for(function()
                assert.spy(callback).was_called(1)
                local stop = timestamp()
                local grace_ms = 25
                assert.is_true((stop - start) >= (100 - grace_ms))
            end, 150)
        end)
    )

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
        "should reject callback-style functions",
        async_test(function()
            local err = assert.has_error(function()
                a.promisify(function(arg1, cb)
                    cb(arg1, nil)
                end, true) "påskmust"
            end)
            assert.equals(err, "påskmust")
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

    it("should accept yielding non-promise values to parent coroutine context", function()
        local thread = coroutine.create(function(val)
            a.run_blocking(function()
                coroutine.yield(val)
            end)
        end)
        local ok, value = coroutine.resume(thread, 1337)
        assert.is_true(ok)
        assert.equals(1337, value)
    end)

    it(
        "should run all suspending functions concurrently",
        async_test(function()
            local start = timestamp()
            local function sleep(ms, ret_val)
                return function()
                    a.sleep(ms)
                    return ret_val
                end
            end
            local one, two, three, four, five = a.wait_all {
                sleep(100, 1),
                sleep(100, "two"),
                sleep(100, "three"),
                sleep(100, 4),
                sleep(100, 5),
            }
            local grace = 50
            local delta = timestamp() - start
            assert.is_true(delta <= (100 + grace))
            assert.is_true(delta >= (100 - grace))
            assert.equals(1, one)
            assert.equals("two", two)
            assert.equals("three", three)
            assert.equals(4, four)
            assert.equals(5, five)
        end)
    )
end)
