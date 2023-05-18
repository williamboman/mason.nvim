local Result = require "mason-core.result"
local api = require "mason-registry.api"
local installer = require "mason-core.installer"
local match = require "luassert.match"
local mock = require "luassert.mock"
local npm = require "mason-core.managers.npm"
local path = require "mason-core.path"
local spawn = require "mason-core.spawn"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

describe("npm manager", function()
    it(
        "should call npm install",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, npm.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.spy(ctx.spawn.npm).was_called_with(match.tbl_containing {
                "install",
                match.tbl_containing {
                    "main-package@42.13.37",
                    "supporting-package",
                    "supporting-package2",
                },
            })
        end)
    )

    it(
        "should call npm init if node_modules and package.json doesnt exist",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            ctx.fs.file_exists = mockx.returns(false)
            ctx.fs.dir_exists = mockx.returns(false)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, function()
                npm.install { "main-package", "supporting-package", "supporting-package2" }
            end)
            assert.spy(ctx.spawn.npm).was_called_with {
                "init",
                "--yes",
                "--scope=mason",
            }
        end)
    )

    it(
        "should append .npmrc file",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            ctx.fs.append_file = spy.new(mockx.just_runs())
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, npm.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.spy(ctx.fs.append_file).was_called(1)
            assert.spy(ctx.fs.append_file).was_called_with(ctx.fs, ".npmrc", "global-style=true")
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "42.13.37" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, npm.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.same({
                type = "npm",
                package = "main-package",
            }, ctx.receipt.primary_source)
            assert.same({
                {
                    type = "npm",
                    package = "supporting-package",
                },
                {
                    type = "npm",
                    package = "supporting-package2",
                },
            }, ctx.receipt.secondary_sources)
        end)
    )
end)

describe("npm version check", function()
    it(
        "should return current version",
        async_test(function()
            stub(spawn, "npm", function()
                return Result.success {
                    stdout = [[
                    {
                      "name": "bash",
                      "dependencies": {
                        "bash-language-server": {
                          "version": "2.0.0",
                          "resolved": "https://registry.npmjs.org/bash-language-server/-/bash-language-server-2.0.0.tgz"
                        }
                      }
                    }
                ]],
                }
            end)

            local result = npm.get_installed_primary_package_version(
                mock.new {
                    primary_source = mock.new {
                        type = "npm",
                        package = "bash-language-server",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.spy(spawn.npm).was_called(1)
            assert.spy(spawn.npm).was_called_with { "ls", "--json", cwd = path.package_prefix "dummy" }
            assert.is_true(result:is_success())
            assert.equals("2.0.0", result:get_or_nil())
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            stub(api, "get")
            api.get.on_call_with("/api/npm/bash-language-server/versions/latest").returns(Result.success {
                name = "bash-language-server",
                version = "2.0.0",
            })
            stub(spawn, "npm", function()
                return Result.success {
                    stdout = [[
                    {
                      "name": "bash",
                      "dependencies": {
                        "bash-language-server": {
                          "version": "1.17.0",
                          "resolved": "https://registry.npmjs.org/bash-language-server/-/bash-language-server-1.17.0.tgz"
                        }
                      }
                    }
                ]],
                }
            end)

            local result = npm.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "npm",
                        package = "bash-language-server",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.is_true(result:is_success())
            assert.same({
                name = "bash-language-server",
                current_version = "1.17.0",
                latest_version = "2.0.0",
            }, result:get_or_nil())
        end)
    )

    it(
        "should return failure if primary package is not outdated",
        async_test(function()
            stub(spawn, "npm", function()
                return Result.success {
                    stdout = [[
                        {
                          "name": "bash",
                          "dependencies": {
                            "bash-language-server": {
                              "version": "1.17.0",
                              "resolved": "https://registry.npmjs.org/bash-language-server/-/bash-language-server-1.17.0.tgz"
                            }
                          }
                        }
                    ]],
                }
            end)
            stub(api, "get")
            api.get.on_call_with("/api/npm/bash-language-server/versions/latest").returns(Result.success {
                name = "bash-language-server",
                version = "1.17.0",
            })

            local result = npm.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "npm",
                        package = "bash-language-server",
                    },
                },
                path.package_prefix "dummy"
            )

            assert.is_true(result:is_failure())
            assert.equals("Primary package is not outdated.", result:err_or_nil())
        end)
    )
end)
