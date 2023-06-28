local installer = require "mason-core.installer"
local luarocks = require "mason-core.installer.managers.luarocks"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

describe("luarocks manager", function()
    it("should install", function()
        local ctx = create_dummy_context()
        stub(ctx, "promote_cwd")
        installer.exec_in_context(ctx, function()
            luarocks.install("my-rock", "1.0.0")
        end)

        assert.spy(ctx.promote_cwd).was_called(1)
        assert.spy(ctx.spawn.luarocks).was_called(1)
        assert.spy(ctx.spawn.luarocks).was_called_with {
            "install",
            { "--tree", ctx.cwd:get() },
            vim.NIL, -- dev
            vim.NIL, -- server
            { "my-rock", "1.0.0" },
        }
    end)

    it("should install dev mode", function()
        local ctx = create_dummy_context()
        stub(ctx, "promote_cwd")
        installer.exec_in_context(ctx, function()
            luarocks.install("my-rock", "1.0.0", {
                dev = true,
            })
        end)

        assert.spy(ctx.promote_cwd).was_called(1)
        assert.spy(ctx.spawn.luarocks).was_called(1)
        assert.spy(ctx.spawn.luarocks).was_called_with {
            "install",
            { "--tree", ctx.cwd:get() },
            "--dev",
            vim.NIL, -- server
            { "my-rock", "1.0.0" },
        }
    end)

    it("should install using provided server", function()
        local ctx = create_dummy_context()
        stub(ctx, "promote_cwd")
        installer.exec_in_context(ctx, function()
            luarocks.install("my-rock", "1.0.0", {
                server = "https://luarocks.org/dev",
            })
        end)

        assert.spy(ctx.promote_cwd).was_called(1)
        assert.spy(ctx.spawn.luarocks).was_called(1)
        assert.spy(ctx.spawn.luarocks).was_called_with {
            "install",
            { "--tree", ctx.cwd:get() },
            vim.NIL, -- dev
            "--server=https://luarocks.org/dev",
            { "my-rock", "1.0.0" },
        }
    end)

    it("should write output", function()
        local ctx = create_dummy_context()
        stub(ctx, "promote_cwd")
        spy.on(ctx.stdio_sink, "stdout")
        installer.exec_in_context(ctx, function()
            luarocks.install("my-rock", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing luarocks package my-rock@1.0.0…\n"
    end)
end)
