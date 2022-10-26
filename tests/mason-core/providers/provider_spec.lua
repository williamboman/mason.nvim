local spy = require "luassert.spy"
local Result = require "mason-core.result"

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
        local failing_provider = {
            github = {
                get_all_release_versions = spy.new(function()
                    return Result.failure "Failed."
                end),
            },
        }
        local successful_provider = {
            github = {
                get_all_release_versions = spy.new(function()
                    return Result.success { "1.0.0", "2.0.0" }
                end),
            },
        }

        provider.register("failing-provider", failing_provider)
        provider.register("successful-provider", successful_provider)

        settings.set {
            providers = { "failing-provider", "successful-provider" },
        }

        assert.same(
            Result.success { "1.0.0", "2.0.0" },
            provider.service.github.get_all_release_versions "sumneko/lua-language-server"
        )
        assert.spy(failing_provider.github.get_all_release_versions).was_called()
        assert.spy(failing_provider.github.get_all_release_versions).was_called_with "sumneko/lua-language-server"
        assert.spy(successful_provider.github.get_all_release_versions).was_called()
        assert.spy(successful_provider.github.get_all_release_versions).was_called_with "sumneko/lua-language-server"
    end)
end)
