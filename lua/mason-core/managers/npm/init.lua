local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local providers = require "mason-core.providers"
local spawn = require "mason-core.spawn"

local list_copy = _.list_copy

local M = {}

local create_bin_path = _.compose(path.concat, function(executable)
    return _.append(executable, { "node_modules", ".bin" })
end, _.if_else(_.always(platform.is.win), _.format "%s.cmd", _.identity))

---@async
---@param ctx InstallContext
local function ensure_npm_root(ctx)
    if not (ctx.fs:dir_exists "node_modules" or ctx.fs:file_exists "package.json") then
        -- Create a package.json to set a boundary for where npm installs packages.
        ctx.spawn.npm { "init", "--yes", "--scope=mason" }
        ctx.stdio_sink.stdout "Initialized npm root\n"
    end
end

---@param packages string[]
local function with_receipt(packages)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.npm(packages[1]))
        for i = 2, #packages do
            ctx.receipt:with_secondary_source(ctx.receipt.npm(packages[i]))
        end
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The npm packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The npm packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.install(packages)
    local ctx = installer.context()
    local pkgs = list_copy(packages)
    ctx.requested_version:if_present(function(version)
        pkgs[1] = ("%s@%s"):format(pkgs[1], version)
    end)

    -- Use global-style. The reasons for this are:
    --   a) To avoid polluting the executables (aka bin-links) that npm creates.
    --   b) The installation is, after all, more similar to a "global" installation. We don't really gain
    --      any of the benefits of not using global style (e.g., deduping the dependency tree).
    --
    --  We write to .npmrc manually instead of going through npm because managing a local .npmrc file
    --  is a bit unreliable across npm versions (especially <7), so we take extra measures to avoid
    --  inadvertently polluting global npm config.
    ctx.fs:append_file(".npmrc", "global-style=true")

    ensure_npm_root(ctx)
    ctx.spawn.npm { "install", pkgs }

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
---@param exec_args string[] The arguments to pass to npm exec.
function M.exec(exec_args)
    local ctx = installer.context()
    ctx.spawn.npm { "exec", "--yes", "--", exec_args }
end

---@async
---@param script string The npm script to run.
function M.run(script)
    local ctx = installer.context()
    ctx.spawn.npm { "run", script }
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if receipt.primary_source.type ~= "npm" then
        return Result.failure "Receipt does not have a primary source of type npm"
    end
    return spawn.npm({ "ls", "--json", cwd = install_dir }):map_catching(function(result)
        local npm_packages = vim.json.decode(result.stdout)
        return npm_packages.dependencies[receipt.primary_source.package].version
    end)
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "npm" then
        return Result.failure "Receipt does not have a primary source of type npm"
    end
    local primary_package = receipt.primary_source.package
    return M.get_installed_primary_package_version(receipt, install_dir)
        :and_then(function(installed_version)
            return providers.npm.get_latest_version(primary_package):map(function(response)
                return {
                    installed = installed_version,
                    latest = response.version,
                }
            end)
        end)
        :and_then(function(versions)
            if versions.installed ~= versions.latest then
                return Result.success {
                    name = primary_package,
                    current_version = versions.installed,
                    latest_version = versions.latest,
                }
            else
                return Result.failure "Primary package is not outdated."
            end
        end)
end

return M
