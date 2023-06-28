local composer = require "mason-core.installer.managers.composer"
local installer = require "mason-core.installer"
local spy = require "luassert.spy"

describe("composer manager", function()
    it("should install", function()
        local ctx = create_dummy_context()
        installer.exec_in_context(ctx, function()
            composer.install("my-package", "1.0.0")
        end)

        assert.spy(ctx.spawn.composer).was_called(2)
        assert.spy(ctx.spawn.composer).was_called_with {
            "init",
            "--no-interaction",
            "--stability=stable",
        }
        assert.spy(ctx.spawn.composer).was_called_with {
            "require",
            "my-package:1.0.0",
        }
    end)

    it("should write output", function()
        local ctx = create_dummy_context()
        spy.on(ctx.stdio_sink, "stdout")

        installer.exec_in_context(ctx, function()
            composer.install("my-package", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing composer package my-package@1.0.0…\n"
    end)
end)
