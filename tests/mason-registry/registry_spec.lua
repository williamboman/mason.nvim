local Pkg = require "mason-core.package"
local registry = require "mason-registry"

describe("mason-registry", function()
    it("should return package", function()
        assert.is_true(getmetatable(registry.get_package "dummy").__index == Pkg)
    end)

    it("should error when getting non-existent package", function()
        local err = assert.has_error(function()
            registry.get_package "non-existent"
        end)
        assert.equals([[Cannot find package "non-existent".]], err)
    end)

    it("should check whether package exists", function()
        assert.is_true(registry.has_package "dummy")
        assert.is_false(registry.has_package "non-existent")
    end)

    it("should get all package specs", function()
        assert.equals(3, #registry.get_all_package_specs())
    end)
end)
