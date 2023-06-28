local Result = require "mason-core.result"
local installer = require "mason-core.installer"
local match = require "luassert.match"
local npm = require "mason-core.installer.managers.npm"
local spawn = require "mason-core.spawn"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

describe("npm manager", function()
    it("should init package.json", function()
        local ctx = create_dummy_context()
        stub(ctx.fs, "append_file")
        stub(spawn, "npm")
        spawn.npm.returns(Result.success {})
        spawn.npm.on_call_with({ "version", "--json" }).returns(Result.success {
            stdout = [[ { "npm": "8.1.0" } ]],
        })
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
        assert.spy(ctx.fs.append_file).was_called_with(match.is_ref(ctx.fs), ".npmrc", "\nglobal-style=true")
    end)

    it("should use install-strategy on npm >= 9", function()
        local ctx = create_dummy_context()
        stub(ctx.fs, "append_file")
        stub(spawn, "npm")
        spawn.npm.returns(Result.success {})
        spawn.npm.on_call_with({ "version", "--json" }).returns(Result.success {
            stdout = [[ { "npm": "9.1.0" } ]],
        })
        installer.exec_in_context(ctx, function()
            npm.init()
        end)

        assert.spy(ctx.spawn.npm).was_called(1)
        assert.spy(ctx.spawn.npm).was_called_with {
            "init",
            "--yes",
            "--scope=mason",
        }
        assert.spy(ctx.fs.append_file).was_called_with(match.is_ref(ctx.fs), ".npmrc", "\ninstall-strategy=shallow")
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

    it("should write output", function()
        local ctx = create_dummy_context()
        spy.on(ctx.stdio_sink, "stdout")

        installer.exec_in_context(ctx, function()
            npm.install("my-package", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing npm package my-package@1.0.0…\n"
    end)
end)
