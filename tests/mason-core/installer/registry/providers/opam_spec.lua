local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local installer = require "mason-core.installer"
local opam = require "mason-core.installer.registry.providers.opam"
local stub = require "luassert.stub"

---@param overrides Purl
local function purl(overrides)
    local purl = Purl.parse("pkg:opam/package@2.2.0"):get_or_throw()
    if not overrides then
        return purl
    end
    return vim.tbl_deep_extend("force", purl, overrides)
end

describe("opam provider :: parsing", function()
    it("should parse package", function()
        assert.same(
            Result.success {
                package = "package",
                version = "2.2.0",
            },
            opam.parse({}, purl())
        )
    end)
end)

describe("opam provider :: installing", function()
    it("should install opam packages", function()
        local ctx = create_dummy_context()
        local manager = require "mason-core.installer.managers.opam"
        stub(manager, "install", mockx.returns(Result.success()))

        local result = installer.exec_in_context(ctx, function()
            return opam.install(ctx, {
                package = "package",
                version = "1.5.0",
            })
        end)

        assert.is_true(result:is_success())
        assert.spy(manager.install).was_called(1)
        assert.spy(manager.install).was_called_with("package", "1.5.0")
    end)
end)
