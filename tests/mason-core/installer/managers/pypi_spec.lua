local Result = require "mason-core.result"
local installer = require "mason-core.installer"
local match = require "luassert.match"
local path = require "mason-core.path"
local pypi = require "mason-core.installer.managers.pypi"
local spawn = require "mason-core.spawn"
local spy = require "luassert.spy"
local stub = require "luassert.stub"

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
    before_each(function()
        stub(spawn, "python3", mockx.returns(Result.success()))
        spawn.python3.on_call_with({ "--version" }).returns(Result.success { stdout = "Python 3.12.0" })
    end)

    it("should init venv without upgrading pip", function()
        local ctx = create_dummy_context()
        stub(ctx, "promote_cwd")

        installer.exec_in_context(ctx, function()
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
        local ctx = create_dummy_context()
        stub(ctx, "promote_cwd")
        stub(ctx.fs, "file_exists")
        ctx.fs.file_exists.on_call_with(match.ref(ctx.fs), "venv/bin/python").returns(true)

        installer.exec_in_context(ctx, function()
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
        local ctx = create_dummy_context()
        stub(ctx.fs, "file_exists")
        ctx.fs.file_exists.on_call_with(match.ref(ctx.fs), "venv/bin/python").returns(true)
        installer.exec_in_context(ctx, function()
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
        local ctx = create_dummy_context()
        stub(ctx.fs, "file_exists")
        ctx.fs.file_exists.on_call_with(match.ref(ctx.fs), "venv/bin/python").returns(true)
        spy.on(ctx.stdio_sink, "stdout")

        installer.exec_in_context(ctx, function()
            pypi.install("pypi-package", "1.0.0")
        end)

        assert.spy(ctx.stdio_sink.stdout).was_called_with "Installing pip package pypi-package@1.0.0…\n"
    end)

    it("should install extra specifier", function()
        local ctx = create_dummy_context()
        stub(ctx.fs, "file_exists")
        ctx.fs.file_exists.on_call_with(match.ref(ctx.fs), "venv/bin/python").returns(true)

        installer.exec_in_context(ctx, function()
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
        local ctx = create_dummy_context()
        stub(ctx.fs, "file_exists")
        ctx.fs.file_exists.on_call_with(match.ref(ctx.fs), "venv/bin/python").returns(true)
        installer.exec_in_context(ctx, function()
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
