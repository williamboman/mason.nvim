local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local process = require "nvim-lsp-installer.process"
local pip3 = require "nvim-lsp-installer.installers.pip3"
local gem = require "nvim-lsp-installer.installers.gem"
local cargo_check = require "nvim-lsp-installer.jobs.outdated-servers.cargo"
local gem_check = require "nvim-lsp-installer.jobs.outdated-servers.gem"
local pip3_check = require "nvim-lsp-installer.jobs.outdated-servers.pip3"
local spawn = require "nvim-lsp-installer.core.async.spawn"

local M = {}

local ServerVersion = {}
ServerVersion.__index = ServerVersion

---@param field_name string
local function version_in_receipt(field_name)
    ---@param receipt InstallReceipt
    ---@return Result
    return function(_, receipt)
        return Result.success(receipt.primary_source[field_name])
    end
end

local function noop()
    return Result.failure "Unable to detect version."
end

---@type Record<InstallReceiptSourceType, fun(server: Server, receipt: InstallReceipt): Result>
local version_checker = {
    ["npm"] = function(server, receipt)
        return spawn.npm({
            "ls",
            "--json",
            cwd = server.root_dir,
        }):map_catching(function(result)
            local npm_packages = vim.json.decode(result.stdout)
            return npm_packages.dependencies[receipt.primary_source.package].version
        end)
    end,
    ["pip3"] = function(server, receipt)
        return spawn.python3({
            "-m",
            "pip",
            "list",
            "--format",
            "json",
            cwd = server.root_dir,
            env = process.graft_env(pip3.env(server.root_dir)),
        }):map_catching(function(result)
            local pip_packages = vim.json.decode(result.stdout)
            local normalized_pip_package = pip3_check.normalize_package(receipt.primary_source.package)
            for _, pip_package in ipairs(pip_packages) do
                if pip_package.name == normalized_pip_package then
                    return pip_package.version
                end
            end
            error "Unable to find pip package."
        end)
    end,
    ["gem"] = function(server, receipt)
        return spawn.gem({
            "list",
            cwd = server.root_dir,
            env = process.graft_env(gem.env(server.root_dir)),
        }):map_catching(function(result)
            local gems = gem_check.parse_gem_list_output(result.stdout)
            if gems[receipt.primary_source.package] then
                return gems[receipt.primary_source.package]
            else
                error "Failed to find gem package version."
            end
        end)
    end,
    ["cargo"] = function(server, receipt)
        return spawn.cargo({
            "install",
            "--list",
            "--root",
            server.root_dir,
            cwd = server.root_dir,
        }):map_catching(function(result)
            local crates = cargo_check.parse_installed_crates(result.stdout)
            a.scheduler() -- needed because vim.fn.* call
            local package = vim.fn.fnamemodify(receipt.primary_source.package, ":t")
            if crates[package] then
                return crates[package]
            else
                error "Failed to find cargo package version."
            end
        end)
    end,
    ["git"] = function(server)
        return spawn.git({
            "rev-parse",
            "--short",
            "HEAD",
            cwd = server.root_dir,
        }):map_catching(function(result)
            return vim.trim(result.stdout)
        end)
    end,
    ["opam"] = noop,
    ["dotnet"] = noop,
    ["r_package"] = noop,
    ["github_release_file"] = version_in_receipt "release",
    ["github_tag"] = version_in_receipt "tag",
    ["jdtls"] = version_in_receipt "version",
}

--- Async function.
---@param server Server
---@return Result
function M.check_server_version(server)
    local receipt = server:get_receipt()
    if not receipt then
        return Result.failure "Unable to retrieve installation receipt."
    end
    local version_check = version_checker[receipt.primary_source.type] or noop
    local ok, result = pcall(version_check, server, receipt)
    if ok then
        return result
    else
        return Result.failure(result)
    end
end

return M
