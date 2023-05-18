local mock = require "luassert.mock"
local stub = require "luassert.stub"

local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local github = require "mason-core.managers.github"
local installer = require "mason-core.installer"
local providers = require "mason-core.providers"

describe("github release file", function()
    it(
        "should use provided version",
        async_test(function()
            stub(providers.github, "get_latest_release")
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            local source = installer.exec_in_context(ctx, function()
                return github.release_file {
                    repo = "williamboman/mason.nvim",
                    asset_file = "program.exe",
                    version = Optional.of "13.37",
                }
            end)
            assert.spy(providers.github.get_latest_release).was_not_called()
            assert.equals("13.37", source.release)
            assert.equals(
                "https://github.com/williamboman/mason.nvim/releases/download/13.37/program.exe",
                source.download_url
            )
        end)
    )

    it(
        "should use use dynamic asset_file",
        async_test(function()
            stub(providers.github, "get_latest_release")
            providers.github.get_latest_release.returns(Result.success(mock.new {
                tag_name = "im_the_tag",
            }))
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            local source = installer.exec_in_context(ctx, function()
                return github.release_file {
                    repo = "williamboman/mason.nvim",
                    asset_file = function(version)
                        return version .. "_for_reals"
                    end,
                }
            end)
            assert.spy(providers.github.get_latest_release).was_called(1)
            assert.spy(providers.github.get_latest_release).was_called_with "williamboman/mason.nvim"
            assert.equals("im_the_tag", source.release)
            assert.equals("im_the_tag_for_reals", source.asset_file)
            assert.equals(
                "https://github.com/williamboman/mason.nvim/releases/download/im_the_tag/im_the_tag_for_reals",
                source.download_url
            )
        end)
    )
end)

describe("github release version", function()
    it(
        "should use provided version",
        async_test(function()
            stub(providers.github, "get_latest_release")
            local handle = InstallHandleGenerator "dummy"
            local ctx = InstallContextGenerator(handle)
            installer.prepare_installer(ctx):get_or_throw()
            local source = installer.exec_in_context(ctx, function()
                return github.release_version {
                    repo = "williamboman/mason.nvim",
                    version = Optional.of "13.37",
                }
            end)
            assert.spy(providers.github.get_latest_release).was_not_called()
            assert.equals("13.37", source.release)
        end)
    )

    it(
        "should fetch latest release from GitHub API",
        async_test(function()
            async_test(function()
                stub(providers.github, "get_latest_release")
                providers.github.get_latest_release.returns(Result.success { tag_name = "v42" })
                local handle = InstallHandleGenerator "dummy"
                local ctx = InstallContextGenerator(handle)
                installer.prepare_installer(ctx):get_or_throw()
                local source = installer.exec_in_context(ctx, function()
                    return github.release_version {
                        repo = "williamboman/mason.nvim",
                    }
                end)
                assert.spy(providers.github.get_latest_release).was_called(1)
                assert.spy(providers.github.get_latest_release).was_called_with "williamboman/mason.nvim"
                assert.equals("v42", source.release)
            end)
        end)
    )
end)
