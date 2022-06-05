local util = require "lspconfig.util"
local servers = require "nvim-lsp-installer.servers"
local middleware = require "nvim-lsp-installer.middleware"

describe("middleware", function()
    local server
    before_each(function()
        -- 1. setup dummy server
        local default_options = {
            cmd = { "dummy-lsp" },
            cmd_env = { PATH = "/keep/my/path/out/your/f/mouth" },
        }
        server = ServerGenerator {
            default_options = default_options,
        }
        servers.register(server)

        -- 2. register hook
        middleware.register_lspconfig_hook()
    end)

    after_each(function()
        -- reset hook
        util.on_setup = nil
    end)

    it(
        "should apply config changes to installed servers",
        async_test(function()
            server:install()
            assert.wait_for(function()
                assert.is_true(server:is_installed())
            end)
            local config = {
                name = "dummy",
                cmd = { "should", "be", "overwritten" },
                custom = "setting",
                cmd_env = { SOME_DEFAULT_ENV = "important" },
            }
            util.on_setup(config)
            assert.same({
                cmd = { "dummy-lsp" },
                name = "dummy",
                custom = "setting",
                cmd_env = {
                    PATH = "/keep/my/path/out/your/f/mouth",
                    SOME_DEFAULT_ENV = "important",
                },
            }, config)
        end)
    )

    it(
        "should not apply config changes to uninstalled servers",
        async_test(function()
            local config = {
                name = "uninstalled_dummy",
                cmd = { "should", "not", "be", "overwritten" },
                custom = "setting",
                cmd_env = { SOME_DEFAULT_ENV = "important" },
            }
            util.on_setup(config)
            assert.same({
                name = "uninstalled_dummy",
                cmd = { "should", "not", "be", "overwritten" },
                custom = "setting",
                cmd_env = { SOME_DEFAULT_ENV = "important" },
            }, config)
        end)
    )
end)
