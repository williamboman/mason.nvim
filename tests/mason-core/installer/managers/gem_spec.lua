local gem = require "mason-core.installer.managers.gem"
local installer = require "mason-core.installer"

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
