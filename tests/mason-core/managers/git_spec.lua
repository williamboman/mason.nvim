local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local mock = require "luassert.mock"
local spawn = require "mason-core.spawn"
local stub = require "luassert.stub"

local git = require "mason-core.managers.git"

describe("git manager", function()
    it(
        "should fail if no git repo provided",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            local err = assert.has_error(function()
                installer.prepare_installer(ctx):get_or_throw()
                installer.exec_in_context(ctx, function()
                    git.clone {}
                end)
            end)
            assert.equals("No git URL provided.", err)
            assert.spy(ctx.spawn.git).was_not_called()
        end)
    )

    it(
        "should clone provided repo",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, function()
                git.clone { "https://github.com/williamboman/mason.nvim.git" }
            end)
            assert.spy(ctx.spawn.git).was_called(1)
            assert.spy(ctx.spawn.git).was_called_with {
                "clone",
                "--depth",
                "1",
                vim.NIL,
                "https://github.com/williamboman/mason.nvim.git",
                ".",
            }
        end)
    )

    it(
        "should fetch and checkout revision if requested",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle, { version = "1337" })
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, function()
                git.clone { "https://github.com/williamboman/mason.nvim.git" }
            end)
            assert.spy(ctx.spawn.git).was_called(3)
            assert.spy(ctx.spawn.git).was_called_with {
                "clone",
                "--depth",
                "1",
                vim.NIL,
                "https://github.com/williamboman/mason.nvim.git",
                ".",
            }
            assert.spy(ctx.spawn.git).was_called_with {
                "fetch",
                "--depth",
                "1",
                "origin",
                "1337",
            }
            assert.spy(ctx.spawn.git).was_called_with { "checkout", "FETCH_HEAD" }
        end)
    )

    it(
        "should provide receipt information",
        async_test(function()
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            installer.exec_in_context(ctx, function()
                git.clone({ "https://github.com/williamboman/mason.nvim.git" }).with_receipt()
            end)
            assert.same({
                type = "git",
                remote = "https://github.com/williamboman/mason.nvim.git",
            }, ctx.receipt.primary_source)
            assert.is_true(#ctx.receipt.secondary_sources == 0)
        end)
    )
end)

describe("git version check", function()
    it(
        "should return current version",
        async_test(function()
            stub(spawn, "git")
            spawn.git.returns(Result.success {
                stdout = [[19c668c]],
            })

            local result = git.get_installed_revision({ type = "git" }, "/tmp/install/dir")

            assert.spy(spawn.git).was_called(1)
            assert.spy(spawn.git).was_called_with { "rev-parse", "--short", "HEAD", cwd = "/tmp/install/dir" }
            assert.is_true(result:is_success())
            assert.equals("19c668c", result:get_or_nil())
        end)
    )

    it(
        "should check for outdated git clone",
        async_test(function()
            stub(spawn, "git")
            spawn.git.returns(Result.success {
                stdout = _.dedent [[
                    728307a74cd5f2dec7ca2ca164785c25673d6328
                    19c668cd10695b243b09452f0dfd53570c1a2e7d
                ]],
            })

            local result = git.check_outdated_git_clone(
                mock.new {
                    primary_source = mock.new {
                        type = "git",
                        remote = "https://github.com/williamboman/mason.nvim.git",
                    },
                },
                "/tmp/install/dir"
            )

            assert.spy(spawn.git).was_called(2)
            assert.spy(spawn.git).was_called_with {
                "fetch",
                "origin",
                "HEAD",
                cwd = "/tmp/install/dir",
            }
            assert.spy(spawn.git).was_called_with {
                "rev-parse",
                "FETCH_HEAD",
                "HEAD",
                cwd = "/tmp/install/dir",
            }
            assert.is_true(result:is_success())
            assert.same({
                name = "https://github.com/williamboman/mason.nvim.git",
                current_version = "19c668cd10695b243b09452f0dfd53570c1a2e7d",
                latest_version = "728307a74cd5f2dec7ca2ca164785c25673d6328",
            }, result:get_or_nil())
        end)
    )

    it(
        "should return failure if clone is not outdated",
        async_test(function()
            stub(spawn, "git")
            spawn.git.returns(Result.success {
                stdout = _.dedent [[
                    19c668cd10695b243b09452f0dfd53570c1a2e7d
                    19c668cd10695b243b09452f0dfd53570c1a2e7d
                ]],
            })

            local result = git.check_outdated_git_clone(
                mock.new {
                    primary_source = mock.new {
                        type = "git",
                        remote = "https://github.com/williamboman/mason.nvim.git",
                    },
                },
                "/tmp/install/dir"
            )

            assert.is_true(result:is_failure())
            assert.equals("Git clone is up to date.", result:err_or_nil())
        end)
    )
end)
