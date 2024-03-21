local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local installer = require "mason-core.installer"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local providers = require "mason-core.providers"
local settings = require "mason.settings"
local spawn = require "mason-core.spawn"

local VENV_DIR = "venv"

local M = {}

local create_bin_path = _.compose(path.concat, function(executable)
    return _.append(executable, { VENV_DIR, platform.is.win and "Scripts" or "bin" })
end, _.if_else(_.always(platform.is.win), _.format "%s.exe", _.identity))

---@param packages string[]
local function with_receipt(packages)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.pip3(packages[1]))
        for i = 2, #packages do
            ctx.receipt:with_secondary_source(ctx.receipt.pip3(packages[i]))
        end
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The pip packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The pip packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.install(packages)
    local ctx = installer.context()
    local pkgs = _.list_copy(packages)

    ctx.requested_version:if_present(function(version)
        pkgs[1] = ("%s==%s"):format(pkgs[1], version)
    end)

    a.scheduler()

    local executables = platform.is.win
            and _.list_not_nil(vim.g.python3_host_prog and vim.fn.expand(vim.g.python3_host_prog), "python", "python3")
        or _.list_not_nil(vim.g.python3_host_prog and vim.fn.expand(vim.g.python3_host_prog), "python3", "python")

    -- pip3 will hardcode the full path to venv executables, so we need to promote cwd to make sure pip uses the final destination path.
    ctx:promote_cwd()

    -- Find first executable that manages to create venv
    local executable = _.find_first(function(executable)
        return pcall(ctx.spawn[executable], { "-m", "venv", VENV_DIR })
    end, executables)

    Optional.of_nilable(executable)
        :if_present(function()
            if settings.current.pip.upgrade_pip then
                ctx.spawn.python {
                    "-m",
                    "pip",
                    "--disable-pip-version-check",
                    "install",
                    "-U",
                    settings.current.pip.install_args,
                    "pip",
                    with_paths = { M.venv_path(ctx.cwd:get()) },
                }
            end
            ctx.spawn.python {
                "-m",
                "pip",
                "--disable-pip-version-check",
                "install",
                "-U",
                settings.current.pip.install_args,
                pkgs,
                with_paths = { M.venv_path(ctx.cwd:get()) },
            }
        end)
        :or_else_throw "Unable to create python3 venv environment."

    if packages.bin then
        _.each(function(bin)
            ctx:link_bin(bin, create_bin_path(bin))
        end, packages.bin)
    end

    return {
        with_receipt = with_receipt(packages),
    }
end

---@param pkg string
---@return string
function M.normalize_package(pkg)
    -- https://stackoverflow.com/a/60307740
    local s = pkg:gsub("%[.*%]", "")
    return s
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "pip3" then
        return Result.failure "Receipt does not have a primary source of type pip3"
    end
    local normalized_package = M.normalize_package(receipt.primary_source.package)
    return M.get_installed_primary_package_version(receipt, install_dir):and_then(function(installed_version)
        return providers.pypi
            .get_latest_version(normalized_package)
            :map(function(latest)
                return {
                    current = installed_version,
                    latest = latest.version,
                }
            end)
            :and_then(function(versions)
                if versions.current ~= versions.latest then
                    return Result.success {
                        name = normalized_package,
                        current_version = versions.current,
                        latest_version = versions.latest,
                    }
                else
                    return Result.failure "Primary package is not outdated."
                end
            end)
    end)
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if receipt.primary_source.type ~= "pip3" then
        return Result.failure "Receipt does not have a primary source of type pip3"
    end
    return spawn
        .python({
            "-m",
            "pip",
            "list",
            "--format=json",
            cwd = install_dir,
            with_paths = { M.venv_path(install_dir) },
        })
        :map_catching(function(result)
            local pip_packages = vim.json.decode(result.stdout)
            local normalized_pip_package = M.normalize_package(receipt.primary_source.package)
            local pip_package = _.find_first(function(pkg)
                return pkg.name == normalized_pip_package
            end, pip_packages)
            return Optional.of_nilable(pip_package)
                :map(function(pkg)
                    return pkg.version
                end)
                :or_else_throw "Unable to find pip package."
        end)
end

---@param install_dir string
function M.venv_path(install_dir)
    return path.concat { install_dir, VENV_DIR, platform.is.win and "Scripts" or "bin" }
end

return M
