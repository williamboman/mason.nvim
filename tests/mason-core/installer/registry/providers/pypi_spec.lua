local Purl = require "mason-core.purl"
local Result = require "mason-core.result"
local installer = require "mason-core.installer"
local pypi = require "mason-core.installer.registry.providers.pypi"
local settings = require "mason.settings"
local stub = require "luassert.stub"

---@param overrides Purl
local function purl(overrides)
    local purl = Purl.parse("pkg:pypi/package@5.5.0"):get_or_throw()
    if not overrides then
        return purl
    end
    return vim.tbl_deep_extend("force", purl, overrides)
end

describe("pypi provider :: parsing", function()
    it("should parse package", function()
        settings.set {
            pip = {
                install_args = { "--proxy", "http://localghost" },
                upgrade_pip = true,
            },
        }

        assert.same(
            Result.success {
                package = "package",
                version = "5.5.0",
                extra_packages = { "extra" },
                pip = {
                    upgrade = true,
                    extra_args = { "--proxy", "http://localghost" },
                    use_uv = false,
                },
            },
            pypi.parse({ extra_packages = { "extra" } }, purl())
        )
        settings.set(settings._DEFAULT_SETTINGS)
    end)

    it("should check supported platforms", function()
        assert.same(Result.failure "PLATFORM_UNSUPPORTED", pypi.parse({ supported_platforms = { "VIC64" } }, purl()))
    end)
end)

describe("pypi provider :: installing", function()
    it("should install pypi packages", function()
        local ctx = create_dummy_context()
        local manager = require "mason-core.installer.managers.pypi"
        stub(manager, "init", mockx.returns(Result.success()))
        stub(manager, "install", mockx.returns(Result.success()))
        settings.set {
            pip = {
                install_args = { "--proxy", "http://localghost" },
                upgrade_pip = true,
            },
        }

        local result = installer.exec_in_context(ctx, function()
            return pypi.install(ctx, {
                package = "package",
                extra = "lsp",
                version = "1.5.0",
                extra_packages = { "extra" },
                pip = {
                    upgrade = true,
                    extra_args = { "--proxy", "http://localghost" },
                },
            })
        end)

        assert.is_true(result:is_success())
        assert.spy(manager.init).was_called(1)
        assert.spy(manager.init).was_called_with {
            package = { name = "package", version = "1.5.0" },
            upgrade_pip = true,
            install_extra_args = { "--proxy", "http://localghost" },
        }
        assert.spy(manager.install).was_called(1)
        assert.spy(manager.install).was_called_with(
            "package",
            "1.5.0",
            { extra = "lsp", extra_packages = { "extra" }, install_extra_args = { "--proxy", "http://localghost" } }
        )
        settings.set(settings._DEFAULT_SETTINGS)
    end)
end)
