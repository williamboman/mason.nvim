local installer = require "mason-core.installer"
local nuget = require "mason-core.installer.managers.nuget"

describe("nuget manager", function()
    it("should install", function()
        local ctx = create_dummy_context()
        installer.exec_in_context(ctx, function()
            nuget.install("nuget-package", "1.0.0")
        end)

        assert.spy(ctx.spawn.dotnet).was_called(1)
        assert.spy(ctx.spawn.dotnet).was_called_with {
            "tool",
            "update",
            "--tool-path",
            ".",
            { "--version", "1.0.0" },
            "nuget-package",
        }
    end)
end)
