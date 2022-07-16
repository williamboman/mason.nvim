local spy = require "luassert.spy"
local stub = require "luassert.stub"
local match = require "luassert.match"

local server_mappings = require "mason-lspconfig.mappings.server"
local filetype_mappings = require "mason-lspconfig.mappings.filetype"
local api = require "mason-lspconfig.api.command"
local registry = require "mason-registry"
local Pkg = require "mason-core.package"

describe(":LspInstall", function()
    server_mappings.lspconfig_to_package["dummylsp"] = "dummy"
    server_mappings.package_to_lspconfig["dummy"] = "dummylsp"
    filetype_mappings.dummylang = { "dummylsp" }

    it("should install the provided servers", function()
        local dummy = registry.get_package "dummy"
        spy.on(Pkg, "install")
        api.LspInstall { "dummylsp@1.0.0" }
        assert.spy(Pkg.install).was_called(1)
        assert.spy(Pkg.install).was_called_with(match.ref(dummy), {
            version = "1.0.0",
        })
    end)

    it(
        "should prompt user for server to install based on filetype",
        async_test(function()
            local dummy = registry.get_package "dummy"
            spy.on(Pkg, "install")
            stub(vim.ui, "select")
            vim.ui.select.invokes(function(items, opts, callback)
                callback "dummylsp"
            end)
            vim.cmd [[new | setf dummylang]]
            api.LspInstall {}
            assert.spy(Pkg.install).was_called(1)
            assert.spy(Pkg.install).was_called_with(match.ref(dummy), {
                version = nil,
            })
            assert.spy(vim.ui.select).was_called(1)
            assert.spy(vim.ui.select).was_called_with({ "dummylsp" }, match.is_table(), match.is_function())
        end)
    )

    it(
        "should not prompt user for server to install if no filetype match exists",
        async_test(function()
            spy.on(Pkg, "install")
            stub(vim.ui, "select")
            vim.cmd [[new | setf nolsplang]]
            api.LspInstall {}
            assert.spy(Pkg.install).was_called(0)
            assert.spy(vim.ui.select).was_called(0)
        end)
    )
end)

describe(":LspUninstall", function()
    server_mappings.lspconfig_to_package["dummylsp"] = "dummy"
    server_mappings.package_to_lspconfig["dummy"] = "dummylsp"
    filetype_mappings.dummylang = { "dummylsp" }

    it("should uninstall the provided servers", function()
        local dummy = registry.get_package "dummy"
        spy.on(Pkg, "uninstall")
        api.LspUninstall { "dummylsp" }
        assert.spy(Pkg.uninstall).was_called(1)
        assert.spy(Pkg.uninstall).was_called_with(match.ref(dummy))
    end)
end)
