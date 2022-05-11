local functional = require "nvim-lsp-installer.core.functional"
local spawn = require "nvim-lsp-installer.core.spawn"
local Optional = require "nvim-lsp-installer.core.optional"
local installer = require "nvim-lsp-installer.core.installer"
local Result = require "nvim-lsp-installer.core.result"
local process = require "nvim-lsp-installer.core.process"
local path = require "nvim-lsp-installer.core.path"

local list_copy = functional.list_copy

local M = {}

---@async
---@param ctx InstallContext
local function ensure_npm_root(ctx)
    if not (ctx.fs:dir_exists "node_modules" or ctx.fs:file_exists "package.json") then
        -- Create a package.json to set a boundary for where npm installs packages.
        ctx.spawn.npm { "init", "--yes", "--scope=lsp-installer" }
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
---@param packages string[] @The npm packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages string[] @The npm packages to install. The first item in this list will be the recipient of the requested version, if set.
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

    return {
        with_receipt = with_receipt(packages),
    }
end

---@async
---@param exec_args string[] @The arguments to pass to npm exec.
function M.exec(exec_args)
    local ctx = installer.context()
    ctx.spawn.npm { "exec", "--yes", "--", exec_args }
end

---@async
---@param script string @The npm script to run.
function M.run(script)
    local ctx = installer.context()
    ctx.spawn.npm { "run", script }
end

---@async
---@param receipt InstallReceipt
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
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "npm" then
        return Result.failure "Receipt does not have a primary source of type npm"
    end
    local primary_package = receipt.primary_source.package
    local npm_outdated = spawn.npm { "outdated", "--json", primary_package, cwd = install_dir }
    if npm_outdated:is_success() then
        return Result.failure "Primary package is not outdated."
    end
    return npm_outdated:recover_catching(function(result)
        assert(result.exit_code == 1, "Expected npm outdated to return exit code 1.")
        local data = vim.json.decode(result.stdout)

        return Optional.of_nilable(data[primary_package])
            :map(function(outdated_package)
                if outdated_package.current ~= outdated_package.latest then
                    return {
                        name = primary_package,
                        current_version = assert(outdated_package.current),
                        latest_version = assert(outdated_package.latest),
                    }
                end
            end)
            :or_else_throw()
    end)
end

---@param install_dir string
function M.env(install_dir)
    return {
        PATH = process.extend_path { path.concat { install_dir, "node_modules", ".bin" } },
    }
end

return M
