local installer = require "mason-core.installer"
local opam = require "mason-core.installer.managers.opam"

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
end)
