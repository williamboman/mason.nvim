local Pkg = require "mason-core.package"
local a = require "mason-core.async"
local match = require "luassert.match"
local mock = require "luassert.mock"
local registry = require "mason-registry"
local spy = require "luassert.spy"
local stub = require "luassert.stub"
local InstallReceipt = require("mason-core.receipt").InstallReceipt

describe("package", function()
    local snapshot

    before_each(function()
        snapshot = assert.snapshot()
    end)

    after_each(function()
        snapshot:revert()
    end)

    before_each(function()
        registry.get_package("dummy"):uninstall()
        package.loaded["dummy_package"] = nil
    end)

    it("should parse package specifiers", function()
        local function parse(str)
            local name, version = Pkg.Parse(str)
            return { name, version }
        end

        assert.same({ "rust-analyzer", nil }, parse "rust-analyzer")
        assert.same({ "rust-analyzer", "" }, parse "rust-analyzer@")
        assert.same({ "rust-analyzer", "nightly" }, parse "rust-analyzer@nightly")
    end)

    it("should validate spec", function()
        local valid_spec = {
            schema = "registry+v1",
            name = "Package name",
            description = "Package description",
            homepage = "https://example.com",
            categories = { Pkg.Cat.LSP },
            languages = { Pkg.Lang.Rust },
            licenses = { Pkg.License.MIT },
            source = {
                id = "pkg:mason/package@1.0.0",
                install = function() end,
            },
        }
        local function modify_spec(fields)
            return setmetatable(fields, { __index = valid_spec })
        end
        assert.equals(
            "name: expected string, got number",
            assert.has_error(function()
                Pkg.new(modify_spec { name = 23 })
            end)
        )

        assert.equals(
            "description: expected string, got number",
            assert.has_error(function()
                Pkg.new(modify_spec { description = 23 })
            end)
        )

        assert.equals(
            "homepage: expected string, got number",
            assert.has_error(function()
                Pkg.new(modify_spec { homepage = 23 })
            end)
        )

        assert.equals(
            "categories: expected table, got number",
            assert.has_error(function()
                Pkg.new(modify_spec { categories = 23 })
            end)
        )

        assert.equals(
            "languages: expected table, got number",
            assert.has_error(function()
                Pkg.new(modify_spec { languages = 23 })
            end)
        )
    end)

    it("should create new handle", function()
        local dummy = registry.get_package "dummy"
        -- yo dawg
        local handle_handler = spy.new()
        dummy:once("handle", handle_handler)
        local handle = dummy:new_handle()
        assert.spy(handle_handler).was_called(1)
        assert.spy(handle_handler).was_called_with(match.ref(handle))
        handle:close()
    end)

    it("should not create new handle if one already exists", function()
        local dummy = registry.get_package "dummy"
        dummy.handle = mock.new {
            is_closed = mockx.returns(false),
        }
        local handle_handler = spy.new()
        dummy:once("handle", handle_handler)
        local err = assert.has_error(function()
            dummy:new_handle()
        end)
        assert.equals("Cannot create new handle because existing handle is not closed.", err)
        assert.spy(handle_handler).was_called(0)
        dummy.handle = nil
    end)

    it("should successfully install package", function()
        local dummy = registry.get_package "dummy"
        local package_install_success_handler = spy.new()
        local package_install_failed_handler = spy.new()
        local install_success_handler = spy.new()
        local install_failed_handler = spy.new()
        registry:once("package:install:success", package_install_success_handler)
        registry:once("package:install:failed", package_install_failed_handler)
        dummy:once("install:success", install_success_handler)
        dummy:once("install:failed", install_failed_handler)

        local handle = dummy:install { version = "1337" }

        assert.wait(function()
            assert.is_true(handle:is_closed())
            assert.is_true(dummy:is_installed())
        end)

        assert.wait(function()
            assert.spy(install_success_handler).was_called(1)
            assert.spy(install_success_handler).was_called_with(match.instanceof(InstallReceipt))
            assert.spy(package_install_success_handler).was_called(1)
            assert
                .spy(package_install_success_handler)
                .was_called_with(match.is_ref(dummy), match.instanceof(InstallReceipt))
            assert.spy(package_install_failed_handler).was_called(0)
            assert.spy(install_failed_handler).was_called(0)
        end)
    end)

    it("should fail to install package", function()
        local dummy = registry.get_package "dummy"
        stub(dummy.spec.source, "install", function()
            error("I simply refuse to be installed.", 0)
        end)
        local package_install_success_handler = spy.new()
        local package_install_failed_handler = spy.new()
        local install_success_handler = spy.new()
        local install_failed_handler = spy.new()
        registry:once("package:install:success", package_install_success_handler)
        registry:once("package:install:failed", package_install_failed_handler)
        dummy:once("install:success", install_success_handler)
        dummy:once("install:failed", install_failed_handler)

        local handle = dummy:install { version = "1337" }

        assert.wait(function()
            assert.is_true(handle:is_closed())
            assert.is_false(dummy:is_installed())
        end)

        assert.wait(function()
            assert.spy(install_failed_handler).was_called(1)
            assert.spy(install_failed_handler).was_called_with "I simply refuse to be installed."
            assert.spy(package_install_failed_handler).was_called(1)
            assert
                .spy(package_install_failed_handler)
                .was_called_with(match.is_ref(dummy), "I simply refuse to be installed.")
            assert.spy(package_install_success_handler).was_called(0)
            assert.spy(install_success_handler).was_called(0)
        end)
    end)

    it("should be able to start package installation outside of main loop", function()
        local dummy = registry.get_package "dummy"

        local handle = a.run_blocking(function()
            -- Move outside the main loop
            a.wait(function(resolve)
                local timer = vim.loop.new_timer()
                timer:start(0, 0, function()
                    timer:close()
                    resolve()
                end)
            end)
            assert.is_true(vim.in_fast_event())

            return assert.is_not.has_error(function()
                return dummy:install()
            end)
        end)

        assert.wait(function()
            assert.is_true(handle:is_closed())
        end)
    end)
end)
