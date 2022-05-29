local _ = require "nvim-lsp-installer.core.functional"
local settings = require "nvim-lsp-installer.settings"
local process = require "nvim-lsp-installer.core.process"
local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local Optional = require "nvim-lsp-installer.core.optional"
local installer = require "nvim-lsp-installer.core.installer"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"

local VENV_DIR = "venv"

local M = {}

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
---@param packages string[] @The pip packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages string[] @The pip packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.install(packages)
    local ctx = installer.context()
    local pkgs = _.list_copy(packages)

    ctx.requested_version:if_present(function(version)
        pkgs[1] = ("%s==%s"):format(pkgs[1], version)
    end)

    local executables = platform.is_win and _.list_not_nil(vim.g.python3_host_prog, "python", "python3")
        or _.list_not_nil(vim.g.python3_host_prog, "python3", "python")

    -- pip3 will hardcode the full path to venv executables, so we need to promote cwd to make sure pip uses the final destination path.
    ctx:promote_cwd()

    -- Find first executable that manages to create venv
    local executable = _.find_first(function(executable)
        return pcall(ctx.spawn[executable], { "-m", "venv", VENV_DIR })
    end, executables)

    Optional.of_nilable(executable)
        :if_present(function()
            ctx.spawn.python {
                "-m",
                "pip",
                "install",
                "-U",
                settings.current.pip.install_args,
                pkgs,
                with_paths = { M.venv_path(ctx.cwd:get()) },
            }
        end)
        :or_else_throw "Unable to create python3 venv environment."

    return {
        with_receipt = with_receipt(packages),
    }
end

---@param package string
---@return string
function M.normalize_package(package)
    -- https://stackoverflow.com/a/60307740
    local s = package:gsub("%[.*%]", "")
    return s
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "pip3" then
        return Result.failure "Receipt does not have a primary source of type pip3"
    end
    local normalized_package = M.normalize_package(receipt.primary_source.package)
    return spawn.python({
        "-m",
        "pip",
        "list",
        "--outdated",
        "--format=json",
        cwd = install_dir,
        with_paths = { M.venv_path(install_dir) },
    }):map_catching(function(result)
        ---@alias PipOutdatedPackage {name: string, version: string, latest_version: string}
        ---@type PipOutdatedPackage[]
        local packages = vim.json.decode(result.stdout)

        local outdated_primary_package = _.find_first(function(outdated_package)
            return outdated_package.name == normalized_package
                and outdated_package.version ~= outdated_package.latest_version
        end, packages)

        return Optional.of_nilable(outdated_primary_package)
            :map(function(package)
                return {
                    name = normalized_package,
                    current_version = assert(package.version),
                    latest_version = assert(package.latest_version),
                }
            end)
            :or_else_throw "Primary package is not outdated."
    end)
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if receipt.primary_source.type ~= "pip3" then
        return Result.failure "Receipt does not have a primary source of type pip3"
    end
    return spawn.python({
        "-m",
        "pip",
        "list",
        "--format=json",
        cwd = install_dir,
        with_paths = { M.venv_path(install_dir) },
    }):map_catching(function(result)
        local pip_packages = vim.json.decode(result.stdout)
        local normalized_pip_package = M.normalize_package(receipt.primary_source.package)
        local pip_package = _.find_first(function(package)
            return package.name == normalized_pip_package
        end, pip_packages)
        return Optional.of_nilable(pip_package)
            :map(function(package)
                return package.version
            end)
            :or_else_throw "Unable to find pip package."
    end)
end

---@param install_dir string
function M.env(install_dir)
    return {
        PATH = process.extend_path { M.venv_path(install_dir) },
    }
end

---@param install_dir string
function M.venv_path(install_dir)
    return path.concat { install_dir, VENV_DIR, platform.is_win and "Scripts" or "bin" }
end

return M
