local Result = require "nvim-lsp-installer.core.result"
local match = require "luassert.match"
local spy = require "luassert.spy"

describe("result", function()
    it("should create success", function()
        local result = Result.success "Hello!"
        assert.is_true(result:is_success())
        assert.is_false(result:is_failure())
        assert.equals("Hello!", result:get_or_nil())
    end)

    it("should create failure", function()
        local result = Result.failure "Hello!"
        assert.is_true(result:is_failure())
        assert.is_false(result:is_success())
        assert.equals("Hello!", result:err_or_nil())
    end)

    it("should return value on get_or_throw()", function()
        local result = Result.success "Hello!"
        local val = result:get_or_throw()
        assert.equals("Hello!", val)
    end)

    it("should throw failure on get_or_throw()", function()
        local result = Result.failure "Hello!"
        local err = assert.has_error(function()
            result:get_or_throw()
        end)
        assert.equals("Hello!", err)
    end)

    it("should map() success", function()
        local result = Result.success "Hello"
        local mapped = result:map(function(x)
            return x .. " World!"
        end)
        assert.equals("Hello World!", mapped:get_or_nil())
        assert.is_nil(mapped:err_or_nil())
    end)

    it("should not map() failure", function()
        local result = Result.failure "Hello"
        local mapped = result:map(function(x)
            return x .. " World!"
        end)
        assert.equals("Hello", mapped:err_or_nil())
        assert.is_nil(mapped:get_or_nil())
    end)

    it("should raise exceptions in map()", function()
        local result = Result.success "failure"
        local err = assert.has_error(function()
            result:map(function()
                error "error"
            end)
        end)
        assert.equals("error", err)
    end)

    it("should map_catching() success", function()
        local result = Result.success "Hello"
        local mapped = result:map_catching(function(x)
            return x .. " World!"
        end)
        assert.equals("Hello World!", mapped:get_or_nil())
        assert.is_nil(mapped:err_or_nil())
    end)

    it("should not map_catching() failure", function()
        local result = Result.failure "Hello"
        local mapped = result:map_catching(function(x)
            return x .. " World!"
        end)
        assert.equals("Hello", mapped:err_or_nil())
        assert.is_nil(mapped:get_or_nil())
    end)

    it("should catch errors in map_catching()", function()
        local result = Result.success "value"
        local mapped = result:map_catching(function()
            error "This is an error"
        end)
        assert.is_false(mapped:is_success())
        assert.is_true(mapped:is_failure())
        assert.is_true(match.has_match "This is an error$"(mapped:err_or_nil()))
    end)

    it("should recover errors", function()
        local result = Result.failure("call an ambulance"):recover(function(err)
            return err .. ". but not for me!"
        end)
        assert.is_true(result:is_success())
        assert.equals("call an ambulance. but not for me!", result:get_or_nil())
    end)

    it("should catch errors in recover", function()
        local result = Result.failure("call an ambulance"):recover_catching(function(err)
            error("Oh no... " .. err, 2)
        end)
        assert.is_true(result:is_failure())
        assert.equals("Oh no... call an ambulance", result:err_or_nil())
    end)

    it("should return results in run_catching", function()
        local result = Result.run_catching(function()
            return "Hello world!"
        end)
        assert.is_true(result:is_success())
        assert.equals("Hello world!", result:get_or_nil())
    end)

    it("should return failures in run_catching", function()
        local result = Result.run_catching(function()
            error("Oh noes", 2)
        end)
        assert.is_true(result:is_failure())
        assert.equals("Oh noes", result:err_or_nil())
    end)

    it("should run on_failure if failure", function()
        local on_success = spy.new()
        local on_failure = spy.new()
        local result = Result.failure("Oh noes"):on_failure(on_failure):on_success(on_success)
        assert.is_true(result:is_failure())
        assert.equals("Oh noes", result:err_or_nil())
        assert.spy(on_failure).was_called(1)
        assert.spy(on_success).was_called(0)
        assert.spy(on_failure).was_called_with "Oh noes"
    end)

    it("should run on_success if success", function()
        local on_success = spy.new()
        local on_failure = spy.new()
        local result = Result.success("Oh noes"):on_failure(on_failure):on_success(on_success)
        assert.is_true(result:is_success())
        assert.equals("Oh noes", result:get_or_nil())
        assert.spy(on_failure).was_called(0)
        assert.spy(on_success).was_called(1)
        assert.spy(on_success).was_called_with "Oh noes"
    end)
end)
