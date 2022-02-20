local dispatcher = require "nvim-lsp-installer.dispatcher"
local spy = require "luassert.spy"
local match = require "luassert.match"

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

    it("calls all registers callbacks, even if one errors", function()
        local server = {}
        local callback1 = spy.new()
        local callback2 = spy.new(function()
            error "I have an error"
        end)
        local callback3 = spy.new()
        local notify = spy.on(vim, "notify")
        dispatcher.register_server_ready_callback(callback1)
        dispatcher.register_server_ready_callback(callback2)
        dispatcher.register_server_ready_callback(callback3)
        dispatcher.dispatch_server_ready(server)

        assert.spy(callback1).was_called(1)
        assert.spy(callback1).was_called_with(server)
        assert.spy(callback2).was_called(1)
        assert.spy(callback2).was_called_with(server)
        assert.spy(callback3).was_called(1)
        assert.spy(callback3).was_called_with(server)
        assert.spy(notify).was_called(1)
        assert.spy(notify).was_called_with(match.has_match "^.*I have an error$", vim.log.levels.ERROR)
    end)
end)
