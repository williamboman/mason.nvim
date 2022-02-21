local spy = require "luassert.spy"
local match = require "luassert.match"
local lsp_installer = require "nvim-lsp-installer"
local server = require "nvim-lsp-installer.server"
local a = require "nvim-lsp-installer.core.async"
local std = require "nvim-lsp-installer.installers.std"
local fs = require "nvim-lsp-installer.fs"
local path = require "nvim-lsp-installer.path"
local settings = require "nvim-lsp-installer.settings"

describe("server", function()
    it(
        "calls registered on_ready handlers upon successful installation",
        async_test(function()
            local on_ready_handler = spy.new()
            local generic_handler = spy.new()

            lsp_installer.on_server_ready(generic_handler)

            local srv = ServerGenerator {
                name = "on_ready_fixture",
                root_dir = server.get_server_root_path "on_ready_fixture",
            }
            srv:on_ready(on_ready_handler)
            srv:install()
            assert.wait_for(function()
                assert.spy(on_ready_handler).was_called(1)
                assert.spy(generic_handler).was_called(1)
                assert.spy(generic_handler).was_called_with(srv)
            end)
            assert.is_true(srv:is_installed())
        end)
    )

    it(
        "doesn't call on_ready handler when server fails installation",
        async_test(function()
            local on_ready_handler = spy.new()
            local generic_handler = spy.new()

            lsp_installer.on_server_ready(generic_handler)

            local srv = FailingServerGenerator {
                name = "on_ready_fixture_failing",
                root_dir = server.get_server_root_path "on_ready_fixture_failing",
            }
            srv:on_ready(on_ready_handler)
            srv:install()
            a.sleep(500)
            assert.spy(on_ready_handler).was_not_called()
            assert.spy(generic_handler).was_not_called()
            assert.is_false(srv:is_installed())
        end)
    )
end)
