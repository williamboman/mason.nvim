local path = require "mason-core.path"
local pypi = require "mason-core.installer.managers.pypi"
local spy = require "luassert.spy"
local stub = require "luassert.stub"
local test_helpers = require "mason-test.helpers"

---@param ctx InstallContext
local function venv_py(ctx)
    return path.concat {
        ctx.cwd:get(),
        "venv",
        "bin",
        "python",
    }
end

describe("pypi manager", function()
    local snapshot

    before_each(function()
        snapshot = assert.snapshot()
    end)

    after_each(function()
        snapshot:revert()
    end)

    it("should init venv without upgrading pip", function()
        local ctx = test_helpers.create_context()
        stub(ctx, "promote_cwd")

        ctx:execute(function()
            pypi.init { upgrade_pip = false }
        end)

        assert.spy(ctx.promote_cwd).was_called(1)
        assert.spy(ctx.spawn.python3).was_called(1)
        assert.spy(ctx.spawn.python3).was_called_with {
            "-m",
            "venv",
            "venv",
        }
    end)

    it("should init venv and upgrade pip", function()
        local ctx = test_helpers.create_context()
        stub(ctx, "promote_cwd")
        ctx:execute(function()
            pypi.init { upgrade_pip = true, install_extra_args = { "--proxy", "http://localhost" } }
        end)

        assert.spy(ctx.promote_cwd).was_called(1)
        assert.spy(ctx.spawn.python3).was_called(1)
        assert.spy(ctx.spawn.python3).was_called_with {
            "-m",
            "venv",
            "venv",
        }
        assert.spy(ctx.spawn[venv_py(ctx)]).was_called(1)
        assert.spy(ctx.spawn[venv_py(ctx)]).was_called_with {
            "-m",
            "pip",
            "--disable-pip-version-check",
            "install",
            "-U",
            { "--proxy", "http://localhost" },
            { "pip" },
        }
    end)

    it("should install", function()
        local ctx = test_helpers.create_context()
        ctx:execute(function()
            pypi.install("pypi-package", "1.0.0")
        end)

        assert.spy(ctx.spawn[venv_py(ctx)]).was_called(1)
        assert.spy(ctx.spawn[venv_py(ctx)]).was_called_with {
            "-m",
            "pip",
            "--disable-pip-version-check",
            "install",
            "-U",
            vim.NIL, -- install_extra_args
            {
                "pypi-package==1.0.0",
                vim.NIL, -- extra_packages
            },
        }
    end)

    it("should write output", function()
        local ctx = test_helpers.create_context()
        spy.on(ctx.stdio_sink, "stdout")

        ctx:execute(function()
            pypi.install("pypi-package", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing pip package pypi-package@1.0.0…\n"
    end)

    it("should install extra specifier", function()
        local ctx = test_helpers.create_context()
        ctx:execute(function()
            pypi.install("pypi-package", "1.0.0", {
                extra = "lsp",
            })
        end)

        assert.spy(ctx.spawn[venv_py(ctx)]).was_called(1)
        assert.spy(ctx.spawn[venv_py(ctx)]).was_called_with {
            "-m",
            "pip",
            "--disable-pip-version-check",
            "install",
            "-U",
            vim.NIL, -- install_extra_args
            {
                "pypi-package[lsp]==1.0.0",
                vim.NIL, -- extra_packages
            },
        }
    end)

    it("should install extra packages", function()
        local ctx = test_helpers.create_context()
        ctx:execute(function()
            pypi.install("pypi-package", "1.0.0", {
                extra_packages = { "extra-package" },
                install_extra_args = { "--proxy", "http://localhost:9000" },
            })
        end)

        assert.spy(ctx.spawn[venv_py(ctx)]).was_called(1)
        assert.spy(ctx.spawn[venv_py(ctx)]).was_called_with {
            "-m",
            "pip",
            "--disable-pip-version-check",
            "install",
            "-U",
            { "--proxy", "http://localhost:9000" },
            {
                "pypi-package==1.0.0",
                { "extra-package" },
            },
        }
    end)
end)
