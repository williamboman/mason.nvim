local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local process = require "nvim-lsp-installer.process"
local pip3 = require "nvim-lsp-installer.installers.pip3"
local gem = require "nvim-lsp-installer.installers.gem"
local cargo_check = require "nvim-lsp-installer.jobs.outdated-servers.cargo"
local gem_check = require "nvim-lsp-installer.jobs.outdated-servers.gem"
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

---@param package string
---@return string
---@TODO DRY
local function normalize_pip3_package(package)
    -- https://stackoverflow.com/a/60307740
    local s = package:gsub("%[.*%]", "")
    return s
end

local function noop()
    return Result.failure "Unable to detect version."
end

---@type Record<InstallReceiptSourceType, fun(server: Server, receipt: InstallReceipt): Result>
local version_checker = {
    ["npm"] = function(server, receipt)
        local stdout = spawn.npm {
            "ls",
            "--json",
            cwd = server.root_dir,
        }
        local npm_packages = vim.json.decode(stdout)
        return Result.success(npm_packages.dependencies[receipt.primary_source.package].version)
    end,
    ["pip3"] = function(server, receipt)
        local stdout = spawn.python3 {
            "-m",
            "pip",
            "list",
            "--format",
            "json",
            cwd = server.root_dir,
            env = process.graft_env(pip3.env(server.root_dir)),
        }
        local pip_packages = vim.json.decode(stdout)
        local normalized_pip_package = normalize_pip3_package(receipt.primary_source.package)
        for _, pip_package in ipairs(pip_packages) do
            if pip_package.name == normalized_pip_package then
                return Result.success(pip_package.version)
            end
        end
        return Result.failure "Failed to find pip package version."
    end,
    ["gem"] = function(server, receipt)
        local stdout = spawn.gem {
            "list",
            cwd = server.root_dir,
            env = process.graft_env(gem.env(server.root_dir)),
        }
        local gems = gem_check.parse_gem_list_output(stdout)
        if gems[receipt.primary_source.package] then
            return Result.success(gems[receipt.primary_source.package])
        else
            return Result.failure "Failed to find gem package version."
        end
    end,
    ["cargo"] = function(server, receipt)
        local stdout = spawn.cargo {
            "install",
            "--list",
            "--root",
            server.root_dir,
            cwd = server.root_dir,
        }
        local crates = cargo_check.parse_installed_crates(stdout)
        a.scheduler() -- needed because vim.fn.* call
        local package = vim.fn.fnamemodify(receipt.primary_source.package, ":t")
        if crates[package] then
            return Result.success(crates[package])
        else
            return Result.failure "Failed to find cargo package version."
        end
    end,
    ["git"] = function(server)
        local stdout = spawn.git {
            "rev-parse",
            "--short",
            "HEAD",
            cwd = server.root_dir,
        }
        return Result.success(vim.trim(stdout))
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
