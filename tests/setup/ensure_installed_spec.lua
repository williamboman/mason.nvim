local spy = require "luassert.spy"
local configs = require "lspconfig.configs"
local servers = require "nvim-lsp-installer.servers"

describe("ensure_installed", function()
    it(
        "should install servers",
        async_test(function()
            local server1_installer_spy = spy.new()
            local server2_installer_spy = spy.new()
            local server1 = ServerGenerator {
                name = "ensure_installed1",
                installer = function()
                    server1_installer_spy()
                end,
            }
            local server2 = ServerGenerator {
                name = "ensure_installed2",
                installer = function()
                    server2_installer_spy()
                end,
            }

            servers.register(server1)
            servers.register(server2)

            configs[server1.name] = { default_config = {} }
            configs[server2.name] = { default_config = {} }

            require("nvim-lsp-installer").setup {
                ensure_installed = { server1.name, server2.name },
            }
            assert.wait_for(function()
                assert.spy(server1_installer_spy).was_called(1)
                assert.spy(server2_installer_spy).was_called(1)
            end)
        end)
    )
end)
