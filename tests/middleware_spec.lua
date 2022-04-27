local util = require "lspconfig.util"
local servers = require "nvim-lsp-installer.servers"
local middleware = require "nvim-lsp-installer.middleware"

describe("middleware", function()
    it("should register on_setup hook with lspconfig", function()
        -- 1. setup dummy server
        local default_options = {
            cmd = { "dummy-lsp" },
            cmd_env = { PATH = "/keep/my/path/out/your/f/mouth" },
        }
        local server = ServerGenerator {
            name = "dummy",
            default_options = default_options,
        }
        servers.register(server)

        -- 2. register hook
        middleware.register_lspconfig_hook()

        -- 3. call lspconfig hook
        local config = {
            name = "dummy",
            cmd = { "should", "be", "overwritten" },
            custom = "setting",
            cmd_env = { SOME_DEFAULT_ENV = "important" },
        }
        util.on_setup(config)
        assert.are.same({
            cmd = { "dummy-lsp" },
            name = "dummy",
            custom = "setting",
            cmd_env = {
                PATH = "/keep/my/path/out/your/f/mouth",
                SOME_DEFAULT_ENV = "important",
            },
        }, config)
    end)
end)
