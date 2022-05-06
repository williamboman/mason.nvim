local spy = require "luassert.spy"
local mock = require "luassert.mock"
local installer = require "nvim-lsp-installer.core.installer"
local Optional = require "nvim-lsp-installer.core.optional"
local composer = require "nvim-lsp-installer.core.managers.composer"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"

describe("composer manager", function()
    ---@type InstallContext
    local ctx
    before_each(function()
        ctx = InstallContextGenerator {
            spawn = mock.new {
                composer = mockx.returns {},
            },
        }
    end)

    it(
        "should call composer require",
        async_test(function()
            ctx.fs.file_exists = mockx.returns(false)
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(
                ctx,
                composer.packages { "main-package", "supporting-package", "supporting-package2" }
            )
            assert.spy(ctx.spawn.composer).was_called(2)
            assert.spy(ctx.spawn.composer).was_called_with {
                "init",
                "--no-interaction",
                "--stability=stable",
            }
            assert.spy(ctx.spawn.composer).was_called_with {
                "require",
                {
                    "main-package:42.13.37",
                    "supporting-package",
                    "supporting-package2",
                },
            }
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(
                ctx,
                composer.packages { "main-package", "supporting-package", "supporting-package2" }
            )
            assert.same({
                type = "composer",
                package = "main-package",
            }, ctx.receipt.primary_source)
            assert.same({
                {
                    type = "composer",
                    package = "supporting-package",
                },
                {
                    type = "composer",
                    package = "supporting-package2",
                },
            }, ctx.receipt.secondary_sources)
        end)
    )
end)

describe("composer version check", function()
    it(
        "should return current version",
        async_test(function()
            spawn.composer = spy.new(function()
                return Result.success {
                    stdout = [[
{
    "name": "vimeo/psalm",
    "versions": [
        "4.0.0"
    ]
}
]],
                }
            end)

            local result = composer.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "composer",
                        package = "vimeo/psalm",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.composer).was_called(1)
            assert.spy(spawn.composer).was_called_with {
                "info",
                "--format=json",
                "vimeo/psalm",
                cwd = "/tmp/install/dir",
            }
            assert.is_true(result:is_success())
            assert.equals("4.0.0", result:get_or_nil())

            spawn.composer = nil
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            spawn.composer = spy.new(function()
                return Result.success {
                    stdout = [[
{
    "installed": [
        {
            "name": "vimeo/psalm",
            "version": "4.0.0",
            "latest": "4.22.0",
            "latest-status": "semver-safe-update",
            "description": "A static analysis tool for finding errors in PHP applications"
        }
    ]
}
]],
                }
            end)

            local result = composer.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "composer",
                        package = "vimeo/psalm",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.composer).was_called(1)
            assert.spy(spawn.composer).was_called_with {
                "outdated",
                "--no-interaction",
                "--format=json",
                cwd = "/tmp/install/dir",
            }
            assert.is_true(result:is_success())
            assert.same({
                name = "vimeo/psalm",
                current_version = "4.0.0",
                latest_version = "4.22.0",
            }, result:get_or_nil())

            spawn.composer = nil
        end)
    )

    it(
        "should return failure if primary package is not outdated",
        async_test(function()
            spawn.composer = spy.new(function()
                return Result.success {
                    stdout = [[{"installed": []}]],
                }
            end)

            local result = composer.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "composer",
                        package = "vimeo/psalm",
                    },
                },
                "/tmp/install/dir"
            )

            assert.is_true(result:is_failure())
            assert.equals("Primary package is not outdated.", result:err_or_nil())
            spawn.composer = nil
        end)
    )
end)
