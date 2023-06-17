local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local gem = require "mason-core.installer.registry.providers.gem"
local installer = require "mason-core.installer"
local stub = require "luassert.stub"

---@param overrides Purl
local function purl(overrides)
    local purl = Purl.parse("pkg:gem/package@1.2.0"):get_or_throw()
    if not overrides then
        return purl
    end
    return vim.tbl_deep_extend("force", purl, overrides)
end

describe("gem provider :: parsing", function()
    it("should parse package", function()
        assert.same(
            Result.success {
                package = "package",
                version = "1.2.0",
                extra_packages = { "extra" },
            },
            gem.parse({ extra_packages = { "extra" } }, purl())
        )
    end)

    it("should check supported platforms", function()
        assert.same(Result.failure "PLATFORM_UNSUPPORTED", gem.parse({ supported_platforms = { "VIC64" } }, purl()))
    end)
end)

describe("gem provider :: installing", function()
    it("should install gem packages", function()
        local ctx = create_dummy_context()
        local manager = require "mason-core.installer.managers.gem"
        stub(manager, "install", mockx.returns(Result.success()))

        local result = installer.exec_in_context(ctx, function()
            return gem.install(ctx, {
                package = "package",
                version = "5.2.0",
                extra_packages = { "extra" },
            })
        end)

        assert.is_true(result:is_success())
        assert.spy(manager.install).was_called(1)
        assert.spy(manager.install).was_called_with("package", "5.2.0", { extra_packages = { "extra" } })
    end)
end)
