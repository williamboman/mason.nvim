local golang = require "mason-core.installer.managers.golang"
local installer = require "mason-core.installer"
local spy = require "luassert.spy"

describe("golang manager", function()
    it("should install", function()
        local ctx = create_dummy_context()

        installer.exec_in_context(ctx, function()
            golang.install("my-golang", "1.0.0")
        end)

        assert.spy(ctx.spawn.go).was_called(1)
        assert.spy(ctx.spawn.go).was_called_with {
            "install",
            "-v",
            "my-golang@1.0.0",
            env = {
                GOBIN = ctx.cwd:get(),
            },
        }
    end)

    it("should write output", function()
        local ctx = create_dummy_context()
        spy.on(ctx.stdio_sink, "stdout")

        installer.exec_in_context(ctx, function()
            golang.install("my-golang", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing go package my-golang@1.0.0…\n"
    end)

    it("should install extra packages", function()
        local ctx = create_dummy_context()
        installer.exec_in_context(ctx, function()
            golang.install("my-golang", "1.0.0", {
                extra_packages = { "extra", "package" },
            })
        end)

        assert.spy(ctx.spawn.go).was_called(3)
        assert.spy(ctx.spawn.go).was_called_with {
            "install",
            "-v",
            "my-golang@1.0.0",
            env = {
                GOBIN = ctx.cwd:get(),
            },
        }
        assert.spy(ctx.spawn.go).was_called_with {
            "install",
            "-v",
            "extra@latest",
            env = {
                GOBIN = ctx.cwd:get(),
            },
        }
        assert.spy(ctx.spawn.go).was_called_with {
            "install",
            "-v",
            "package@latest",
            env = {
                GOBIN = ctx.cwd:get(),
            },
        }
    end)
end)
