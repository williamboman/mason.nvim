local match = require "luassert.match"
local stub = require "luassert.stub"
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
        stub(Pkg, "is_installed")
        Pkg.is_installed.returns(false)
        mason_lspconfig.setup { ensure_installed = { "dummylsp@1.0.0" } }
        assert.spy(Pkg.install).was_called(1)
        assert.spy(Pkg.install).was_called_with(match.ref(dummy), {
            version = "1.0.0",
        })
    end)
end)

describe("mason-lspconfig setup_handlers", function()
    server_mappings.lspconfig_to_package["dummylsp"] = "dummy"
    server_mappings.package_to_lspconfig["dummy"] = "dummylsp"
    filetype_mappings.dummylang = { "dummylsp" }

    it("should call default handler", function()
        stub(registry, "get_installed_package_names")
        registry.get_installed_package_names.returns { "dummy" }
        local default_handler = spy.new()

        mason_lspconfig.setup_handlers { default_handler }

        assert.spy(default_handler).was_called(1)
        assert.spy(default_handler).was_called_with "dummylsp"
    end)

    it("should call dedicated handler", function()
        stub(registry, "get_installed_package_names")
        registry.get_installed_package_names.returns { "dummy" }
        local dedicated_handler = spy.new()
        local default_handler = spy.new()

        mason_lspconfig.setup_handlers {
            default_handler,
            ["dummylsp"] = dedicated_handler,
        }

        assert.spy(default_handler).was_called(0)
        assert.spy(dedicated_handler).was_called(1)
        assert.spy(dedicated_handler).was_called_with "dummylsp"
    end)

    it("should print warning if registering handler for non-existent server name", function()
        spy.on(vim, "notify")
        mason_lspconfig.setup_handlers {
            doesnt_exist_server = spy.new(),
        }
        assert.spy(vim.notify).was_called(1)
        assert.spy(vim.notify).was_called_with(
            "[mason.nvim] mason-lspconfig.setup_handlers: Received handler for unknown lspconfig server name: doesnt_exist_server.",
            vim.log.levels.WARN
        )
    end)
end)
