local Result = require "mason-core.result"
local build = require "mason-core.installer.managers.build"
local match = require "luassert.match"
local mock = require "luassert.mock"
local spy = require "luassert.spy"
local stub = require "luassert.stub"
local test_helper = require "mason-test.helpers"

describe("build manager", function()
    local snapshot

    before_each(function()
        snapshot = assert.snapshot()
    end)

    after_each(function()
        snapshot:revert()
    end)

    it("should run build instruction", function()
        local ctx = test_helper.create_context()
        local uv = require "mason-core.async.uv"
        spy.on(ctx, "promote_cwd")
        stub(uv, "write")
        stub(uv, "shutdown")
        stub(uv, "close")
        local stdin = mock.new()
        stub(
            ctx.spawn,
            "bash", ---@param args SpawnArgs
            function(args)
                args.on_spawn(mock.new(), { stdin })
                return Result.success()
            end
        )

        local result = ctx:execute(function()
            return build.run {
                run = [[npm install && npm run compile]],
                env = {
                    MASON_VERSION = "2023-03-09",
                    SOME_VALUE = "here",
                },
            }
        end)

        assert.is_true(result:is_success())
        assert.spy(ctx.promote_cwd).was_called(0)
        assert.spy(ctx.spawn.bash).was_called(1)
        assert.spy(ctx.spawn.bash).was_called_with(match.tbl_containing {
            on_spawn = match.is_function(),
            env = match.same {
                MASON_VERSION = "2023-03-09",
                SOME_VALUE = "here",
            },
        })
        assert.spy(uv.write).was_called(2)
        assert.spy(uv.write).was_called_with(stdin, "set -euxo pipefail;\n")
        assert.spy(uv.write).was_called_with(stdin, "npm install && npm run compile")
        assert.spy(uv.shutdown).was_called_with(stdin)
        assert.spy(uv.close).was_called_with(stdin)
    end)

    it("should promote cwd if not staged", function()
        local ctx = test_helper.create_context()
        stub(ctx, "promote_cwd")

        local result = ctx:execute(function()
            return build.run {
                run = "make",
                staged = false,
            }
        end)

        assert.is_true(result:is_success())
        assert.spy(ctx.promote_cwd).was_called(1)
        assert.spy(ctx.spawn.bash).was_called(1)
    end)
end)
