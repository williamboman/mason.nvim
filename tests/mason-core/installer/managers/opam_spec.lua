local installer = require "mason-core.installer"
local opam = require "mason-core.installer.managers.opam"
local spy = require "luassert.spy"

describe("opam manager", function()
    it("should install", function()
        local ctx = create_dummy_context()

        installer.exec_in_context(ctx, function()
            opam.install("opam-package", "1.0.0")
        end)

        assert.spy(ctx.spawn.opam).was_called(1)
        assert.spy(ctx.spawn.opam).was_called_with {
            "install",
            "--destdir=.",
            "--yes",
            "--verbose",
            "opam-package.1.0.0",
        }
    end)

    it("should write output", function()
        local ctx = create_dummy_context()
        spy.on(ctx.stdio_sink, "stdout")

        installer.exec_in_context(ctx, function()
            opam.install("opam-package", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing opam package opam-package@1.0.0…\n"
    end)
end)
