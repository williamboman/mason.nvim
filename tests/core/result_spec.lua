local Result = require "nvim-lsp-installer.core.result"
local match = require "luassert.match"

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
end)
