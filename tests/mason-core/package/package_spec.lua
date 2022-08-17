local spy = require "luassert.spy"
local mock = require "luassert.mock"
local stub = require "luassert.stub"
local match = require "luassert.match"
local Pkg = require "mason-core.package"
local registry = require "mason-registry"
local Result = require "mason-core.result"

describe("package", function()
    before_each(function()
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
            name = "Package name",
            desc = "Package description",
            homepage = "https://example.com",
            categories = { Pkg.Cat.LSP },
            languages = { Pkg.Lang.Rust },
            install = function() end,
        }
        local function spec(fields)
            return setmetatable(fields, { __index = valid_spec })
        end
        assert.equals(
            "name: expected string, got number",
            assert.has_error(function()
                Pkg.new(spec { name = 23 })
            end)
        )

        assert.equals(
            "desc: expected string, got number",
            assert.has_error(function()
                Pkg.new(spec { desc = 23 })
            end)
        )

        assert.equals(
            "homepage: expected string, got number",
            assert.has_error(function()
                Pkg.new(spec { homepage = 23 })
            end)
        )

        assert.equals(
            "categories: expected table, got number",
            assert.has_error(function()
                Pkg.new(spec { categories = 23 })
            end)
        )

        assert.equals(
            "languages: expected table, got number",
            assert.has_error(function()
                Pkg.new(spec { languages = 23 })
            end)
        )

        assert.equals(
            "install: expected function, got number",
            assert.has_error(function()
                Pkg.new(spec { install = 23 })
            end)
        )
    end)

    it("should create new handle", function()
        ---@type Package
        local dummy = registry.get_package "dummy"
        -- yo dawg
        local handle_handler = spy.new()
        dummy:once("handle", handle_handler)
        local handle = dummy:new_handle()
        assert.spy(handle_handler).was_called(1)
        assert.spy(handle_handler).was_called_with(match.ref(handle))
    end)

    it("should not create new handle if one already exists", function()
        ---@type Package
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
    end)

    it("should successfully install package", function()
        local installer = require "mason-core.installer"
        stub(installer, "execute")
        installer.execute.returns(Result.success "Yay!")
        ---@type Package
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

        assert.spy(installer.execute).was_called(1)
        assert.spy(installer.execute).was_called_with(match.is_ref(handle), { requested_version = "1337" })
        assert.spy(install_success_handler).was_called(1)
        assert.spy(install_success_handler).was_called_with(match.is_ref(handle))
        assert.spy(package_install_success_handler).was_called(1)
        assert.spy(package_install_success_handler).was_called_with(match.is_ref(dummy), match.is_ref(handle))
        assert.spy(package_install_failed_handler).was_called(0)
        assert.spy(install_failed_handler).was_called(0)
    end)

    it("should fail to install package", function()
        local installer = require "mason-core.installer"
        stub(installer, "execute")
        installer.execute.returns(Result.failure "Oh no.")
        ---@type Package
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

        assert.spy(installer.execute).was_called(1)
        assert.spy(installer.execute).was_called_with(match.is_ref(handle), { requested_version = "1337" })
        assert.spy(install_failed_handler).was_called(1)
        assert.spy(install_failed_handler).was_called_with(match.is_ref(handle))
        assert.spy(package_install_failed_handler).was_called(1)
        assert.spy(package_install_failed_handler).was_called_with(match.is_ref(dummy), match.is_ref(handle))
        assert.spy(package_install_success_handler).was_called(0)
        assert.spy(install_success_handler).was_called(0)
    end)
end)
