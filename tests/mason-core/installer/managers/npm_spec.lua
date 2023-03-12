local installer = require "mason-core.installer"
local stub = require "luassert.stub"
local match = require "luassert.match"
local npm = require "mason-core.installer.managers.npm"

describe("npm manager", function()
    it("should init package.json", function()
        local ctx = create_dummy_context()
        stub(ctx.fs, "append_file")
        installer.exec_in_context(ctx, function()
            npm.init()
        end)

        assert.spy(ctx.spawn.npm).was_called(1)
        assert.spy(ctx.spawn.npm).was_called_with {
            "init",
            "--yes",
            "--scope=mason",
        }
        assert.spy(ctx.fs.append_file).was_called(1)
        assert.spy(ctx.fs.append_file).was_called_with(match.is_ref(ctx.fs), ".npmrc", "global-style=true")
    end)

    it("should install", function()
        local ctx = create_dummy_context()
        installer.exec_in_context(ctx, function()
            npm.install("my-package", "1.0.0")
        end)

        assert.spy(ctx.spawn.npm).was_called(1)
        assert.spy(ctx.spawn.npm).was_called_with {
            "install",
            "my-package@1.0.0",
            vim.NIL, -- extra_packages
        }
    end)

    it("should install extra packages", function()
        local ctx = create_dummy_context()
        installer.exec_in_context(ctx, function()
            npm.install("my-package", "1.0.0", {
                extra_packages = { "extra-package" },
            })
        end)

        assert.spy(ctx.spawn.npm).was_called(1)
        assert.spy(ctx.spawn.npm).was_called_with {
            "install",
            "my-package@1.0.0",
            { "extra-package" },
        }
    end)
end)
