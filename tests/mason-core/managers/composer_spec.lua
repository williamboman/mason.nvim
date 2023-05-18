local Result = require "mason-core.result"
local composer = require "mason-core.managers.composer"
local installer = require "mason-core.installer"
local mock = require "luassert.mock"
local path = require "mason-core.path"
local spawn = require "mason-core.spawn"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

describe("composer manager", function()
    it(
        "should call composer require",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            ctx.fs.file_exists = spy.new(mockx.returns(false))
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(
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
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(
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
            stub(spawn, "composer")
            spawn.composer.returns(Result.success {
                stdout = [[
                    {
                        "name": "vimeo/psalm",
                        "versions": [
                            "4.0.0"
                        ]
                    }
                ]],
            })

            local result = composer.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "composer",
                        package = "vimeo/psalm",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.spy(spawn.composer).was_called(1)
            assert.spy(spawn.composer).was_called_with {
                "info",
                "--format=json",
                "vimeo/psalm",
                cwd = path.package_prefix "dummy",
            }
            assert.is_true(result:is_success())
            assert.equals("4.0.0", result:get_or_nil())
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            stub(spawn, "composer")
            spawn.composer.returns(Result.success {
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
            })

            local result = composer.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "composer",
                        package = "vimeo/psalm",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.spy(spawn.composer).was_called(1)
            assert.spy(spawn.composer).was_called_with {
                "outdated",
                "--no-interaction",
                "--format=json",
                cwd = path.package_prefix "dummy",
            }
            assert.is_true(result:is_success())
            assert.same({
                name = "vimeo/psalm",
                current_version = "4.0.0",
                latest_version = "4.22.0",
            }, result:get_or_nil())
        end)
    )

    it(
        "should return failure if primary package is not outdated",
        async_test(function()
            stub(spawn, "composer")
            spawn.composer.returns(Result.success {
                stdout = [[{"installed": []}]],
            })

            local result = composer.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "composer",
                        package = "vimeo/psalm",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.is_true(result:is_failure())
            assert.equals("Primary package is not outdated.", result:err_or_nil())
        end)
    )
end)
