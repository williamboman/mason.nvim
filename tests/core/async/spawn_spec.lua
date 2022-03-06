local spawn = require "nvim-lsp-installer.core.async.spawn"
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
end)
