local spy = require "luassert.spy"
local process = require "nvim-lsp-installer.core.process"

describe("process.attempt", function()
    it("should attempt job variants until first successful one", function()
        local on_finish = spy.new()
        local on_iterate = spy.new()
        local success = function(cb)
            cb(true)
        end
        local fail = function(cb)
            cb(false)
        end

        local job1 = spy.new(fail)
        local job2 = spy.new(fail)
        local job3 = spy.new(success)
        local job4 = spy.new(success)
        local job5 = spy.new(fail)

        process.attempt {
            jobs = { job1, job2, job3, job4, job5 },
            on_iterate = on_iterate,
            on_finish = on_finish,
        }

        assert.spy(job1).was_called(1)
        assert.spy(job2).was_called(1)
        assert.spy(job3).was_called(1)
        assert.spy(job4).was_called(0)
        assert.spy(job5).was_called(0)
        assert.spy(on_iterate).was_called(2)
        assert.spy(on_finish).was_called(1)
        assert.spy(on_finish).was_called_with(true)
    end)

    it("should call on_finish with false if all variants fail", function()
        local on_finish = spy.new()
        local on_iterate = spy.new()
        local fail = function(cb)
            cb(false)
        end

        local job1 = spy.new(fail)
        local job2 = spy.new(fail)
        local job3 = spy.new(fail)

        process.attempt {
            jobs = { job1, job2, job3 },
            on_iterate = on_iterate,
            on_finish = on_finish,
        }

        assert.spy(job1).was_called(1)
        assert.spy(job2).was_called(1)
        assert.spy(job3).was_called(1)
        assert.spy(on_iterate).was_called(2)
        assert.spy(on_finish).was_called(1)
        assert.spy(on_finish).was_called_with(false)
    end)
end)

describe("process.spawn", function()
    -- Unix only
    it(
        "should spawn command and feed output to sink",
        async_test(function()
            local stdio = process.in_memory_sink()
            local callback = spy.new()
            process.spawn("env", {
                args = {},
                env = {
                    "HELLO=world",
                    "MY_ENV=var",
                },
                stdio_sink = stdio.sink,
            }, callback)

            assert.wait_for(function()
                assert.spy(callback).was_called(1)
                assert.spy(callback).was_called_with(true, 0)
                assert.equal(table.concat(stdio.buffers.stdout, ""), "HELLO=world\nMY_ENV=var\n")
            end)
        end)
    )
end)

describe("process.chain", function()
    -- Unix only
    it(
        "should chain commands",
        async_test(function()
            local stdio = process.in_memory_sink()
            local callback = spy.new()

            local c = process.chain {
                env = {
                    "HELLO=world",
                    "MY_ENV=var",
                },
                stdio_sink = stdio.sink,
            }

            c.run("env", {})
            c.run("bash", { "-c", "echo Hello $HELLO" })
            c.spawn(callback)

            assert.wait_for(function()
                assert.spy(callback).was_called(1)
                assert.spy(callback).was_called_with(true)
                assert.equal(table.concat(stdio.buffers.stdout, ""), "HELLO=world\nMY_ENV=var\nHello world\n")
            end)
        end)
    )

    -- Unix only
    it(
        "should abort chain commands should one fail",
        async_test(function()
            local stdio = process.in_memory_sink()
            local callback = spy.new()

            local c = process.chain {
                env = {
                    "HELLO=world",
                    "MY_ENV=var",
                },
                stdio_sink = stdio.sink,
            }

            c.run("env", {})
            c.run("bash", { "-c", ">&2 echo Uh oh; exit 1" })
            c.run("bash", { "-c", "echo Hello $HELLO" })
            c.spawn(callback)

            assert.wait_for(function()
                assert.spy(callback).was_called(1)
                assert.spy(callback).was_called_with(false)
                assert.equal(table.concat(stdio.buffers.stdout, ""), "HELLO=world\nMY_ENV=var\n")
                assert.equal(table.concat(stdio.buffers.stderr, ""), "Uh oh\n")
            end)
        end)
    )
end)
