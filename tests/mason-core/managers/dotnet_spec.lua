local dotnet = require "mason-core.managers.dotnet"
local installer = require "mason-core.installer"

describe("dotnet manager", function()
    it(
        "should call dotnet tool update",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, dotnet.package "main-package")
            assert.spy(ctx.spawn.dotnet).was_called(1)
            assert.spy(ctx.spawn.dotnet).was_called_with {
                "tool",
                "update",
                "--ignore-failed-sources",
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
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, dotnet.package "main-package")
            assert.same({
                type = "dotnet",
                package = "main-package",
            }, ctx.receipt.primary_source)
        end)
    )
end)
