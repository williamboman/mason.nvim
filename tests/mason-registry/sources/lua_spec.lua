local LuaRegistrySource = require "mason-registry.sources.lua"

describe("Lua registry source", function()
    it("should get package", function()
        package.loaded["pkg-index"] = {
            ["my-pkg"] = "pkg-index.my-pkg",
        }
        package.loaded["pkg-index.my-pkg"] = {}
        local source = LuaRegistrySource.new {
            mod = "pkg-index",
        }
        assert.is_not_nil(source:get_package "my-pkg")
        assert.is_nil(source:get_package "non-existent")
    end)

    it("should get all package names", function()
        package.loaded["pkg-index"] = {
            ["my-pkg"] = "pkg-index.my-pkg",
            ["rust-analyzer"] = "pkg-index.rust-analyzer",
            ["typescript-language-server"] = "pkg-index.typescript-language-server",
        }
        local source = LuaRegistrySource.new {
            mod = "pkg-index",
        }
        local package_names = source:get_all_package_names()
        table.sort(package_names)
        assert.same({
            "my-pkg",
            "rust-analyzer",
            "typescript-language-server",
        }, package_names)
    end)

    it("should check if is installed", function()
        package.loaded["pkg-index"] = {}
        local installed_source = LuaRegistrySource.new {
            mod = "pkg-index",
        }
        local uninstalled_source = LuaRegistrySource.new {
            mod = "non-existent",
        }

        assert.is_true(installed_source:is_installed())
        assert.is_false(uninstalled_source:is_installed())
    end)

    it("should stringify instances", function()
        assert.equals("LuaRegistrySource(mod=pkg-index)", tostring(LuaRegistrySource.new { mod = "pkg-index" }))
    end)
end)
