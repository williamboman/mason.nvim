local spy = require "luassert.spy"
local match = require "luassert.match"
local mock = require "luassert.mock"
local Optional = require "nvim-lsp-installer.core.optional"
local installer = require "nvim-lsp-installer.core.installer"
local npm = require "nvim-lsp-installer.core.managers.npm"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"

describe("npm manager", function()
    ---@type InstallContext
    local ctx
    before_each(function()
        ctx = InstallContextGenerator {
            spawn = mock.new {
                npm = mockx.returns {},
            },
        }
    end)

    it(
        "should call npm install",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, npm.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.spy(ctx.spawn.npm).was_called(1)
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
            ctx.fs.file_exists = mockx.returns(false)
            ctx.fs.dir_exists = mockx.returns(false)
            installer.run_installer(ctx, function()
                npm.install { "main-package", "supporting-package", "supporting-package2" }
            end)
            assert.spy(ctx.spawn.npm).was_called_with {
                "init",
                "--yes",
                "--scope=lsp-installer",
            }
        end)
    )

    it(
        "should append .npmrc file",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, npm.packages { "main-package", "supporting-package", "supporting-package2" })
            assert.spy(ctx.fs.append_file).was_called(1)
            assert.spy(ctx.fs.append_file).was_called_with(ctx.fs, ".npmrc", "global-style=true")
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            ctx.requested_version = Optional.of "42.13.37"
            installer.run_installer(ctx, npm.packages { "main-package", "supporting-package", "supporting-package2" })
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
            spawn.npm = spy.new(function()
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
                "/tmp/install/dir"
            )

            assert.spy(spawn.npm).was_called(1)
            assert.spy(spawn.npm).was_called_with { "ls", "--json", cwd = "/tmp/install/dir" }
            assert.is_true(result:is_success())
            assert.equals("2.0.0", result:get_or_nil())

            spawn.npm = nil
        end)
    )

    it(
        "should return outdated primary package",
        async_test(function()
            spawn.npm = spy.new(function()
                -- npm outdated returns with exit code 1 if outdated packages are found!
                return Result.failure {
                    exit_code = 1,
                    stdout = [[
                    {
                      "bash-language-server": {
                        "current": "1.17.0",
                        "wanted": "1.17.0",
                        "latest": "2.0.0",
                        "dependent": "bash",
                        "location": "/tmp/install/dir"
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
                "/tmp/install/dir"
            )

            assert.spy(spawn.npm).was_called(1)
            assert.spy(spawn.npm).was_called_with {
                "outdated",
                "--json",
                "bash-language-server",
                cwd = "/tmp/install/dir",
            }
            assert.is_true(result:is_success())
            assert.same({
                name = "bash-language-server",
                current_version = "1.17.0",
                latest_version = "2.0.0",
            }, result:get_or_nil())

            spawn.npm = nil
        end)
    )

    it(
        "should return failure if primary package is not outdated",
        async_test(function()
            spawn.npm = spy.new(function()
                return Result.success {
                    stdout = "{}",
                }
            end)

            local result = npm.check_outdated_primary_package(
                mock.new {
                    primary_source = mock.new {
                        type = "npm",
                        package = "bash-language-server",
                    },
                },
                "/tmp/install/dir"
            )

            assert.is_true(result:is_failure())
            assert.equals("Primary package is not outdated.", result:err_or_nil())
            spawn.npm = nil
        end)
    )
end)
