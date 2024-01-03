local Result = require "mason-core.result"
local common = require "mason-core.installer.managers.common"
local installer = require "mason-core.installer"
local match = require "luassert.match"
local mock = require "luassert.mock"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

describe("build manager", function()
    it("should run build instruction", function()
        local ctx = create_dummy_context()
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

        local result = installer.exec_in_context(ctx, function()
            return common.run_build_instruction {
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
        local ctx = create_dummy_context()
        stub(ctx, "promote_cwd")
        stub(ctx.spawn, "bash", mockx.returns(Result.success()))

        local result = installer.exec_in_context(ctx, function()
            return common.run_build_instruction {
                run = "make",
                staged = false,
            }
        end)

        assert.is_true(result:is_success())
        assert.spy(ctx.promote_cwd).was_called(1)
        assert.spy(ctx.spawn.bash).was_called(1)
    end)
end)
