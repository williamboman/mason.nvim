local dispatcher = require "nvim-lsp-installer.dispatcher"
local spy = require "luassert.spy"

describe("dispatcher", function()
    it("calls registered callbacks", function()
        local server = {}
        local callback = spy.new()
        dispatcher.register_server_ready_callback(callback)
        dispatcher.dispatch_server_ready(server)

        assert.spy(callback).was_called(1)
        assert.spy(callback).was_called_with(server)
    end)

    it("deregisters callbacks", function()
        local server = {}
        local callback = spy.new()
        local deregister = dispatcher.register_server_ready_callback(callback)
        deregister()
        dispatcher.dispatch_server_ready(server)

        assert.spy(callback).was_not_called()
    end)
end)
