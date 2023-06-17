local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local composer = require "mason-core.installer.registry.providers.composer"
local installer = require "mason-core.installer"
local stub = require "luassert.stub"

---@param overrides Purl
local function purl(overrides)
    local purl = Purl.parse("pkg:composer/vendor/package@2.0.0"):get_or_throw()
    if not overrides then
        return purl
    end
    return vim.tbl_deep_extend("force", purl, overrides)
end

describe("composer provider :: parsing", function()
    it("should parse package", function()
        assert.same(
            Result.success {
                package = "vendor/package",
                version = "2.0.0",
            },
            composer.parse({}, purl())
        )
    end)
end)

describe("composer provider :: installing", function()
    it("should install composer packages", function()
        local ctx = create_dummy_context()
        local manager = require "mason-core.installer.managers.composer"
        stub(manager, "install", mockx.returns(Result.success()))

        local result = installer.exec_in_context(ctx, function()
            return composer.install(ctx, {
                package = "vendor/package",
                version = "1.2.0",
            })
        end)

        assert.is_true(result:is_success())
        assert.spy(manager.install).was_called(1)
        assert.spy(manager.install).was_called_with("vendor/package", "1.2.0")
    end)
end)
