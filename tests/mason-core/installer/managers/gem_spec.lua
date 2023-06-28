local gem = require "mason-core.installer.managers.gem"
local installer = require "mason-core.installer"
local spy = require "luassert.spy"

describe("gem manager", function()
    it("should install", function()
        local ctx = create_dummy_context()
        installer.exec_in_context(ctx, function()
            gem.install("my-gem", "1.0.0")
        end)

        assert.spy(ctx.spawn.gem).was_called(1)
        assert.spy(ctx.spawn.gem).was_called_with {
            "install",
            "--no-user-install",
            "--no-format-executable",
            "--install-dir=.",
            "--bindir=bin",
            "--no-document",
            "my-gem:1.0.0",
            vim.NIL, -- extra_packages
            env = {
                GEM_HOME = ctx.cwd:get(),
            },
        }
    end)

    it("should write output", function()
        local ctx = create_dummy_context()
        spy.on(ctx.stdio_sink, "stdout")
        installer.exec_in_context(ctx, function()
            gem.install("my-gem", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing gem my-gem@1.0.0…\n"
    end)

    it("should install extra packages", function()
        local ctx = create_dummy_context()
        installer.exec_in_context(ctx, function()
            gem.install("my-gem", "1.0.0", {
                extra_packages = { "extra-gem" },
            })
        end)

        assert.spy(ctx.spawn.gem).was_called(1)
        assert.spy(ctx.spawn.gem).was_called_with {
            "install",
            "--no-user-install",
            "--no-format-executable",
            "--install-dir=.",
            "--bindir=bin",
            "--no-document",
            "my-gem:1.0.0",
            { "extra-gem" },
            env = {
                GEM_HOME = ctx.cwd:get(),
            },
        }
    end)
end)
