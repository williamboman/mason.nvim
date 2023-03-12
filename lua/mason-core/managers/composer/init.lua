local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local spawn = require "mason-core.spawn"

local M = {}

local create_bin_path = _.compose(path.concat, function(executable)
    return _.append(executable, { "vendor", "bin" })
end, _.if_else(_.always(platform.is.win), _.format "%s.bat", _.identity))

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
---@param packages { [number]: string, bin: string[]? } The composer packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.require(packages).with_receipt()
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The composer packages to install. The first item in this list will be the recipient of the requested version, if set.
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

    if packages.bin then
        _.each(function(executable)
            ctx:link_bin(executable, create_bin_path(executable))
        end, packages.bin)
    end

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
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "composer" then
        return Result.failure "Receipt does not have a primary source of type composer"
    end
    return spawn
        .composer({
            "outdated",
            "--no-interaction",
            "--format=json",
            cwd = install_dir,
        })
        :map_catching(function(result)
            local outdated_packages = vim.json.decode(result.stdout)
            local outdated_package = _.find_first(function(pkg)
                return pkg.name == receipt.primary_source.package
            end, outdated_packages.installed)
            return Optional.of_nilable(outdated_package)
                :map(function(pkg)
                    if pkg.version ~= pkg.latest then
                        return {
                            name = pkg.name,
                            current_version = pkg.version,
                            latest_version = pkg.latest,
                        }
                    end
                end)
                :or_else_throw "Primary package is not outdated."
        end)
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if receipt.primary_source.type ~= "composer" then
        return Result.failure "Receipt does not have a primary source of type composer"
    end
    return spawn
        .composer({
            "info",
            "--format=json",
            receipt.primary_source.package,
            cwd = install_dir,
        })
        :map_catching(function(result)
            local info = vim.json.decode(result.stdout)
            return info.versions[1]
        end)
end

return M
