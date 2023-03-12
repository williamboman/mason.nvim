local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local process = require "mason-core.process"
local providers = require "mason-core.providers"
local spawn = require "mason-core.spawn"

local M = {}

---@param install_dir string
local function env(install_dir)
    return {
        GEM_HOME = install_dir,
        GEM_PATH = install_dir,
        PATH = process.extend_path { path.concat { install_dir, "bin" } },
    }
end

local create_bin_path = _.compose(path.concat, function(executable)
    return _.append(executable, { "bin" })
end, _.if_else(_.always(platform.is.win), _.format "%s.bat", _.identity))

---@async
---@param executable string
local function link_executable(executable)
    local ctx = installer.context()
    local bin_path = create_bin_path(executable)
    if not ctx.fs:file_exists(bin_path) then
        error(("Cannot link Gem executable %q because it doesn't exist in %q."):format(executable, bin_path), 0)
    end
    ctx:link_bin(
        executable,
        ctx:write_shell_exec_wrapper(executable, path.concat { ctx.package:get_install_path(), bin_path }, {
            GEM_PATH = platform.when {
                unix = function()
                    return ("%s:$GEM_PATH"):format(ctx.package:get_install_path())
                end,
                win = function()
                    return ("%s;%%GEM_PATH%%"):format(ctx.package:get_install_path())
                end,
            },
        })
    )
end

---@param packages string[]
local function with_receipt(packages)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.gem(packages[1]))
        for i = 2, #packages do
            ctx.receipt:with_secondary_source(ctx.receipt.gem(packages[i]))
        end
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The Gem packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The Gem packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.install(packages)
    local ctx = installer.context()
    local pkgs = _.list_copy(packages or {})

    ctx.requested_version:if_present(function(version)
        pkgs[1] = ("%s:%s"):format(pkgs[1], version)
    end)

    ctx.spawn.gem {
        "install",
        "--no-user-install",
        "--no-format-executable",
        "--install-dir=.",
        "--bindir=bin",
        "--no-document",
        pkgs,
        env = {
            GEM_HOME = ctx.cwd:get(),
        },
    }

    if packages.bin then
        _.each(link_executable, packages.bin)
    end

    return {
        with_receipt = with_receipt(packages),
    }
end

---@alias GemOutdatedPackage {name:string, current_version: string, latest_version: string}

---Parses the stdout of the `gem list` command into a table<package_name, version>
---@param output string
function M.parse_gem_list_output(output)
    ---@type table<string, string>
    local gem_versions = {}
    for _, line in ipairs(vim.split(output, "\n")) do
        local gem_package, version = line:match "^(%S+) %((%S+)%)$"
        if gem_package and version then
            gem_versions[gem_package] = version
        end
    end
    return gem_versions
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "gem" then
        return Result.failure "Receipt does not have a primary source of type gem"
    end
    return M.get_installed_primary_package_version(receipt, install_dir)
        :and_then(function(installed_version)
            return providers.rubygems.get_latest_version(receipt.primary_source.package):map(function(latest)
                return {
                    installed = installed_version,
                    latest = latest.version,
                }
            end)
        end)
        :and_then(function(versions)
            if versions.installed ~= versions.latest then
                return Result.success {
                    name = receipt.primary_source.package,
                    current_version = versions.installed,
                    latest_version = versions.latest,
                }
            else
                return Result.failure "Primary package is not outdated."
            end
        end)
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    return spawn
        .gem({
            "list",
            cwd = install_dir,
            env = env(install_dir),
        })
        :map_catching(function(result)
            local gems = M.parse_gem_list_output(result.stdout)
            return Optional.of_nilable(gems[receipt.primary_source.package])
                :or_else_throw "Failed to find gem package version."
        end)
end

return M
