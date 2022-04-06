local spy = require "luassert.spy"
local match = require "luassert.match"
local spawn = require "nvim-lsp-installer.core.spawn"
local process = require "nvim-lsp-installer.process"

describe("async spawn", function()
    it(
        "should spawn commands and return stdout & stderr",
        async_test(function()
            local result = spawn.env {
                env = { "FOO=bar" },
            }
            assert.is_true(result:is_success())
            assert.equals("FOO=bar\n", result:get_or_nil().stdout)
            assert.equals("", result:get_or_nil().stderr)
        end)
    )

    it(
        "should use provided stdio_sink",
        async_test(function()
            local stdio = process.in_memory_sink()
            local result = spawn.env {
                env = { "FOO=bar" },
                stdio_sink = stdio.sink,
            }
            assert.is_true(result:is_success())
            assert.equals(nil, result:get_or_nil().stdout)
            assert.equals(nil, result:get_or_nil().stderr)
            assert.equals("FOO=bar\n", table.concat(stdio.buffers.stdout, ""))
            assert.equals("", table.concat(stdio.buffers.stderr, ""))
        end)
    )

    it(
        "should pass command arguments",
        async_test(function()
            local result = spawn.bash {
                "-c",
                'echo "Hello $VAR"',
                env = { "VAR=world" },
            }

            assert.is_true(result:is_success())
            assert.equals("Hello world\n", result:get_or_nil().stdout)
            assert.equals("", result:get_or_nil().stderr)
        end)
    )

    it(
        "should ignore vim.NIL args",
        async_test(function()
            local result = spawn.bash {
                vim.NIL,
                spawn._when(true, "-c"),
                spawn._when(false, "shouldnotbeincluded"),
                vim.NIL,
                'echo "Hello $VAR"',
                env = { "VAR=world" },
            }

            assert.is_true(result:is_success())
            assert.equals("Hello world\n", result:get_or_nil().stdout)
            assert.equals("", result:get_or_nil().stderr)
        end)
    )

    it(
        "should flatten table args",
        async_test(function()
            local result = spawn.bash {
                { "-c", 'echo "Hello $VAR"' },
                env = { "VAR=world" },
            }

            assert.is_true(result:is_success())
            assert.equals("Hello world\n", result:get_or_nil().stdout)
            assert.equals("", result:get_or_nil().stderr)
        end)
    )

    it(
        "should call on_spawn",
        async_test(function()
            local on_spawn = spy.new(function(_, stdio)
                local stdin = stdio[1]
                stdin:write "im so piped rn"
                stdin:close()
            end)

            local result = spawn.cat {
                { "-" },
                on_spawn = on_spawn,
            }

            assert.spy(on_spawn).was_called(1)
            assert.spy(on_spawn).was_called_with(match.is_not.is_nil(), match.is_not.is_nil())
            assert.is_true(result:is_success())
            assert.equals("im so piped rn", result:get_or_nil().stdout)
        end)
    )

    it(
        "should not call on_spawn if spawning fails",
        async_test(function()
            local on_spawn = spy.new()

            local result = spawn.this_cmd_doesnt_exist {
                on_spawn = on_spawn,
            }

            assert.spy(on_spawn).was_called(0)
            assert.is_true(result:is_failure())
        end)
    )
end)
