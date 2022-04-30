local spy = require "luassert.spy"
local lspconfig = require "lspconfig"
local configs = require "lspconfig.configs"
local servers = require "nvim-lsp-installer.servers"

describe("automatic_installation_exclude", function()
    it(
        "should install servers set up via lspconfig",
        async_test(function()
            local server1_installer_spy = spy.new()
            local server2_installer_spy = spy.new()
            local server1 = ServerGenerator {
                name = "automatic_installation_exclude1",
                installer = function()
                    server1_installer_spy()
                end,
            }
            local server2 = ServerGenerator {
                name = "automatic_installation_exclude2",
                installer = function()
                    server2_installer_spy()
                end,
            }

            servers.register(server1)
            servers.register(server2)

            configs[server1.name] = { default_config = {} }
            configs[server2.name] = { default_config = {} }

            require("nvim-lsp-installer").setup {
                automatic_installation = { exclude = { server2.name } },
            }

            lspconfig[server1.name].setup {}
            lspconfig[server2.name].setup {}

            assert.wait_for(function()
                assert.spy(server1_installer_spy).was_called(1)
                assert.spy(server2_installer_spy).was_called(0)
            end)
        end)
    )
end)
