local match = require "luassert.match"
local spy = require "luassert.spy"

local Pkg = require "mason-core.package"
local mason_lspconfig = require "mason-lspconfig"
local server_mappings = require "mason-lspconfig.mappings.server"
local registry = require "mason-registry"
local filetype_mappings = require "mason-lspconfig.mappings.filetype"

describe("mason-lspconfig setup", function()
    server_mappings.lspconfig_to_package["dummylsp"] = "dummy"
    server_mappings.package_to_lspconfig["dummy"] = "dummylsp"
    filetype_mappings.dummylang = { "dummylsp" }

    it("should set up user commands", function()
        mason_lspconfig.setup()
        local user_commands = vim.api.nvim_get_commands {}

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            nargs = "*",
            complete = "custom",
            definition = "Install one or more LSP servers.",
        }(user_commands["LspInstall"]))

        assert.is_true(match.tbl_containing {
            bang = false,
            bar = false,
            definition = "Uninstall one or more LSP servers.",
            nargs = "+",
            complete = "custom",
        }(user_commands["LspUninstall"]))
    end)

    it("should install servers listed in ensure_installed", function()
        local dummy = registry.get_package "dummy"
        spy.on(Pkg, "install")
        mason_lspconfig.setup { ensure_installed = { "dummylsp@1.0.0" } }
        assert.spy(Pkg.install).was_called(1)
        assert.spy(Pkg.install).was_called_with(match.ref(dummy), {
            version = "1.0.0",
        })
    end)
end)
