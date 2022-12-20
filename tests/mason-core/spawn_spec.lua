local spy = require "luassert.spy"
local stub = require "luassert.stub"
local match = require "luassert.match"
local spawn = require "mason-core.spawn"
local process = require "mason-core.process"

describe("async spawn", function()
    it(
        "should spawn commands and return stdout & stderr",
        async_test(function()
            local result = spawn.env {
                env_raw = { "FOO=bar" },
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
                env_raw = { "FOO=bar" },
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
                env = { VAR = "world" },
            }

            assert.is_true(result:is_success())
            assert.equals("Hello world\n", result:get_or_nil().stdout)
            assert.equals("", result:get_or_nil().stderr)
        end)
    )

    it(
        "should ignore vim.NIL args",
        async_test(function()
            spy.on(process, "spawn")
            local result = spawn.bash {
                vim.NIL,
                vim.NIL,
                "-c",
                { vim.NIL, vim.NIL },
                'echo "Hello $VAR"',
                env = { VAR = "world" },
            }

            assert.is_true(result:is_success())
            assert.equals("Hello world\n", result:get_or_nil().stdout)
            assert.equals("", result:get_or_nil().stderr)
            assert.spy(process.spawn).was_called(1)
            assert.spy(process.spawn).was_called_with(
                match.matches "bash$",
                match.tbl_containing {
                    stdio_sink = match.tbl_containing {
                        stdout = match.is_function(),
                        stderr = match.is_function(),
                    },
                    env = match.list_containing "VAR=world",
                    args = match.tbl_containing {
                        "-c",
                        'echo "Hello $VAR"',
                    },
                },
                match.is_function()
            )
        end)
    )

    it(
        "should flatten table args",
        async_test(function()
            local result = spawn.bash {
                { "-c", 'echo "Hello $VAR"' },
                env = { VAR = "world" },
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
            assert.spy(on_spawn).was_called_with(match.is_not.is_nil(), match.is_table(), match.is_number())
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

    it(
        "should handle failure to spawn process",
        async_test(function()
            stub(process, "spawn", function(_, _, callback)
                callback(false)
            end)

            local result = spawn.bash {}
            assert.spy(process.spawn).was_called(1)
            assert.is_true(result:is_failure())
            assert.is_nil(result:err_or_nil().exit_code)
        end)
    )

    it(
        "should format failure message",
        async_test(function()
            stub(process, "spawn", function(cmd, opts, callback)
                opts.stdio_sink.stderr(("This is an error message for %s!"):format(cmd))
                callback(false, 127)
            end)

            local result = spawn.bash {}
            assert.is_true(result:is_failure())
            assert.is_true(
                match.matches "spawn: .+bash failed with exit code 127 and signal %-%. This is an error message for .+bash!"(
                    tostring(result:err_or_nil())
                )
            )
        end)
    )

    it(
        "should fail if unable to expand command",
        async_test(function()
            spy.on(process, "spawn")
            stub(vim.fn, "exepath", function()
                return ""
            end)

            local result = spawn.unexpand_cmd {}
            assert.is_true(result:is_failure())
            assert.is_true(
                match.matches "spawn: unexpand_cmd failed with exit code %- and signal %-%. unexpand_cmd is not executable"(
                    tostring(result:err_or_nil())
                )
            )
        end)
    )

    it(
        "should not expand cmd if custom PATH is used",
        async_test(function()
            stub(process, "spawn", function(_, _, callback)
                callback(false, 127)
            end)

            local result = spawn.my_cmd { "arg1", env = { PATH = "/bin" } }
            assert.is_true(result:is_failure())
            assert.spy(process.spawn).was_called(1)
            assert.spy(process.spawn).was_called_with(
                "my_cmd",
                match.tbl_containing {
                    args = match.same { "arg1" },
                },
                match.is_function()
            )
        end)
    )

    it(
        "should skip expanding command if with_paths is provided",
        async_test(function()
            stub(process, "spawn", function(_, _, callback)
                callback(false, 127)
            end)

            local result = spawn.custom_path { "arg1", with_paths = {} }
            assert.is_true(result:is_failure())
            assert.spy(process.spawn).was_called(1)
            assert.spy(process.spawn).was_called_with(
                "custom_path",
                match.tbl_containing {
                    args = match.same { "arg1" },
                },
                match.is_function()
            )
        end)
    )

    it(
        "should use expanded command path",
        async_test(function()
            stub(vim.fn, "exepath", function()
                return "/abs/path/to/cmd"
            end)
            stub(process, "spawn", function(_, _, callback)
                callback(false)
            end)

            spawn.the_command { "arg1", "arg2" }
            assert.spy(vim.fn.exepath).was_called(1)
            assert.spy(vim.fn.exepath).was_called_with "the_command"
            assert.spy(process.spawn).was_called(1)
            assert.spy(process.spawn).was_called_with(
                "/abs/path/to/cmd",
                match.tbl_containing {
                    args = match.same { "arg1", "arg2" },
                },
                match.is_function()
            )
        end)
    )
end)
