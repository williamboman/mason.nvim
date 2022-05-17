local _ = require "nvim-lsp-installer.core.functional"
local process = require "nvim-lsp-installer.core.process"
local path = require "nvim-lsp-installer.core.path"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"
local Optional = require "nvim-lsp-installer.core.optional"
local installer = require "nvim-lsp-installer.core.installer"

local M = {}

---@param packages string[]
local function with_receipt(packages)
    return function()
        local ctx = installer.context()

        ctx.receipt:with_primary_source(ctx.receipt.composer(packages[1]))
        for i = 2, #packages do
            ctx.receipt:with_secondary_source(ctx.receipt.composer(packages[i]))
        end
    end
end

---@async
---@param packages string[] The composer packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return function()
        return M.require(packages).with_receipt()
    end
end

---@async
---@param packages string[] The composer packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.require(packages)
    local ctx = installer.context()
    local pkgs = _.list_copy(packages)

    if not ctx.fs:file_exists "composer.json" then
        ctx.spawn.composer { "init", "--no-interaction", "--stability=stable" }
    end

    ctx.requested_version:if_present(function(version)
        pkgs[1] = ("%s:%s"):format(pkgs[1], version)
    end)

    ctx.spawn.composer { "require", pkgs }

    return {
        with_receipt = with_receipt(packages),
    }
end

---@async
function M.install()
    local ctx = installer.context()
    ctx.spawn.composer {
        "install",
        "--no-interaction",
        "--no-dev",
        "--optimize-autoloader",
        "--classmap-authoritative",
    }
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "composer" then
        return Result.failure "Receipt does not have a primary source of type composer"
    end
    return spawn.composer({
        "outdated",
        "--no-interaction",
        "--format=json",
        cwd = install_dir,
    }):map_catching(function(result)
        local outdated_packages = vim.json.decode(result.stdout)
        local outdated_package = _.find_first(function(package)
            return package.name == receipt.primary_source.package
        end, outdated_packages.installed)
        return Optional.of_nilable(outdated_package)
            :map(function(package)
                if package.version ~= package.latest then
                    return {
                        name = package.name,
                        current_version = package.version,
                        latest_version = package.latest,
                    }
                end
            end)
            :or_else_throw "Primary package is not outdated."
    end)
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if receipt.primary_source.type ~= "composer" then
        return Result.failure "Receipt does not have a primary source of type composer"
    end
    return spawn.composer({
        "info",
        "--format=json",
        receipt.primary_source.package,
        cwd = install_dir,
    }):map_catching(function(result)
        local info = vim.json.decode(result.stdout)
        return info.versions[1]
    end)
end

---@param install_dir string
function M.env(install_dir)
    return {
        PATH = process.extend_path { path.concat { install_dir, "vendor", "bin" } },
    }
end

return M
