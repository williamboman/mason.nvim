local mock = require "luassert.mock"
local Optional = require "nvim-lsp-installer.core.optional"
local dotnet = require "nvim-lsp-installer.core.managers.dotnet"

describe("dotnet manager", function()
    ---@type InstallContext
    local ctx
    before_each(function()
        ctx = InstallContextGenerator {
            spawn = mock.new {
                dotnet = mockx.returns {},
            },
        }
    end)

    it(
        "should call dotnet tool update",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            dotnet.package "main-package"(ctx)
            assert.spy(ctx.spawn.dotnet).was_called(1)
            assert.spy(ctx.spawn.dotnet).was_called_with {
                "tool",
                "update",
                "--tool-path",
                ".",
                { "--version", "42.13.37" },
                "main-package",
            }
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            dotnet.package "main-package"(ctx)
            assert.equals(
                vim.inspect {
                    type = "dotnet",
                    package = "main-package",
                },
                vim.inspect(ctx.receipt.primary_source)
            )
        end)
    )
end)
