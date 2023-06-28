local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local installer = require "mason-core.installer"
local log = require "mason-core.log"
local path = require "mason-core.path"
local platform = require "mason-core.platform"

local M = {}

local VENV_DIR = "venv"

---@async
---@param py_executables string[]
local function create_venv(py_executables)
    local ctx = installer.context()
    return Optional.of_nilable(_.find_first(function(executable)
        return ctx.spawn[executable]({ "-m", "venv", VENV_DIR }):is_success()
    end, py_executables)):ok_or "Failed to create python3 virtual environment."
end

---@async
---@param args SpawnArgs
local function venv_python(args)
    local ctx = installer.context()
    local python_path = path.concat {
        ctx.cwd:get(),
        VENV_DIR,
        platform.is.win and "Scripts" or "bin",
        platform.is.win and "python.exe" or "python",
    }
    return ctx.spawn[python_path](args)
end

---@async
---@param pkgs string[]
---@param extra_args? string[]
local function pip_install(pkgs, extra_args)
    return venv_python {
        "-m",
        "pip",
        "--disable-pip-version-check",
        "install",
        "-U",
        extra_args or vim.NIL,
        pkgs,
    }
end

---@async
---@param opts { upgrade_pip: boolean, install_extra_args?: string[] }
function M.init(opts)
    return Result.try(function(try)
        log.fmt_debug("pypi: init", opts)
        local ctx = installer.context()

        a.scheduler()

        local executables = platform.is.win
                and _.list_not_nil(
                    vim.g.python3_host_prog and vim.fn.expand(vim.g.python3_host_prog),
                    "python",
                    "python3"
                )
            or _.list_not_nil(vim.g.python3_host_prog and vim.fn.expand(vim.g.python3_host_prog), "python3", "python")

        -- pip3 will hardcode the full path to venv executables, so we need to promote cwd to make sure pip uses the final destination path.
        ctx:promote_cwd()

        ctx.stdio_sink.stdout "Creating virtual environment…\n"
        try(create_venv(executables))

        if opts.upgrade_pip then
            ctx.stdio_sink.stdout "Upgrading pip inside the virtual environment…\n"
            try(pip_install({ "pip" }, opts.install_extra_args))
        end
    end)
end

---@async
---@param pkg string
---@param version string
---@param opts? { extra?: string, extra_packages?: string[], install_extra_args?: string[] }
function M.install(pkg, version, opts)
    opts = opts or {}
    log.fmt_debug("pypi: install %s %s", pkg, version, opts)
    local ctx = installer.context()
    ctx.stdio_sink.stdout(("Installing pip package %s@%s…\n"):format(pkg, version))
    return pip_install({
        opts.extra and ("%s[%s]==%s"):format(pkg, opts.extra, version) or ("%s==%s"):format(pkg, version),
        opts.extra_packages or vim.NIL,
    }, opts.install_extra_args)
end

---@param exec string
function M.bin_path(exec)
    return Result.pcall(platform.when, {
        unix = function()
            return path.concat { "venv", "bin", exec }
        end,
        win = function()
            return path.concat { "venv", "Scripts", ("%s.exe"):format(exec) }
        end,
    })
end

return M
