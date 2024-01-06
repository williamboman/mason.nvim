local Result = require "mason-core.result"
local installer = require "mason-core.installer"
local match = require "luassert.match"
local platform = require "mason-core.platform"
local util = require "mason-core.installer.registry.util"

describe("registry installer util", function()
    it("should coalesce single target", function()
        local source = { value = "here" }
        local coalesced = util.coalesce_by_target(source, {}):get_or_nil()
        assert.is_true(match.is_ref(source)(coalesced))
    end)

    it("should coalesce multiple targets", function()
        local source = { target = "VIC64", value = "here" }
        local coalesced = util.coalesce_by_target({
            {
                target = "linux_arm64",
                value = "here",
            },
            source,
        }, { target = "VIC64" }):get_or_nil()

        assert.is_true(match.is_ref(source)(coalesced))
    end)

    it("should accept valid platform", function()
        platform.is.VIC64 = true
        local result = util.ensure_valid_platform {
            "VIC64",
            "linux_arm64",
        }
        assert.is_true(result:is_success())
        platform.is.VIC64 = nil
    end)

    it("should reject invalid platform", function()
        local result = util.ensure_valid_platform { "VIC64" }
        assert.same(Result.failure "PLATFORM_UNSUPPORTED", result)
    end)

    it("should accept valid version", function()
        local ctx = create_dummy_context { version = "1.0.0" }
        local result = installer.exec_in_context(ctx, function()
            return util.ensure_valid_version(function()
                return Result.success { "1.0.0", "2.0.0", "3.0.0" }
            end)
        end)
        assert.is_true(result:is_success())
    end)

    it("should reject invalid version", function()
        local ctx = create_dummy_context { version = "13.3.7" }
        local result = installer.exec_in_context(ctx, function()
            return util.ensure_valid_version(function()
                return Result.success { "1.0.0", "2.0.0", "3.0.0" }
            end)
        end)
        assert.same(Result.failure [[Version "13.3.7" is not available.]], result)
    end)

    it("should gracefully accept version if unable to resolve available versions", function()
        local ctx = create_dummy_context { version = "13.3.7" }
        local result = installer.exec_in_context(ctx, function()
            return util.ensure_valid_version(function()
                return Result.failure()
            end)
        end)
        assert.is_true(result:is_success())
    end)

    it("should accept version if in force mode", function()
        local ctx = create_dummy_context { version = "13.3.7", force = true }
        local result = installer.exec_in_context(ctx, function()
            return util.ensure_valid_version(function()
                return Result.success { "1.0.0" }
            end)
        end)
        assert.is_true(result:is_success())
    end)
end)
