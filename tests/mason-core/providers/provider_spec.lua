local Result = require "mason-core.result"
local spy = require "luassert.spy"

describe("providers", function()
    ---@module "mason-core.providers"
    local provider
    ---@module "mason.settings"
    local settings

    before_each(function()
        package.loaded["mason-core.providers"] = nil
        package.loaded["mason.settings"] = nil
        provider = require "mason-core.providers"
        settings = require "mason.settings"
    end)

    it("should run provided providers", function()
        package.loaded["failing-provider"] = {
            github = {
                get_all_release_versions = spy.new(function()
                    return Result.failure "Failed."
                end),
            },
        }
        package.loaded["really-failing-provider"] = {
            github = {
                get_all_release_versions = spy.new(function()
                    error "Failed."
                end),
            },
        }
        package.loaded["successful-provider"] = {
            github = {
                get_all_release_versions = spy.new(function()
                    return Result.success { "1.0.0", "2.0.0" }
                end),
            },
        }

        settings.set {
            providers = { "failing-provider", "really-failing-provider", "successful-provider" },
        }

        assert.same(
            Result.success { "1.0.0", "2.0.0" },
            provider.github.get_all_release_versions "sumneko/lua-language-server"
        )
        assert.spy(package.loaded["failing-provider"].github.get_all_release_versions).was_called()
        assert
            .spy(package.loaded["failing-provider"].github.get_all_release_versions)
            .was_called_with "sumneko/lua-language-server"
        assert.spy(package.loaded["really-failing-provider"].github.get_all_release_versions).was_called()
        assert
            .spy(package.loaded["really-failing-provider"].github.get_all_release_versions)
            .was_called_with "sumneko/lua-language-server"
        assert.spy(package.loaded["successful-provider"].github.get_all_release_versions).was_called()
        assert
            .spy(package.loaded["successful-provider"].github.get_all_release_versions)
            .was_called_with "sumneko/lua-language-server"
    end)
end)
