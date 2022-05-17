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
        ctx.receipt:with_primary_source(ctx.receipt.gem(packages[1]))
        for i = 2, #packages do
            ctx.receipt:with_secondary_source(ctx.receipt.gem(packages[i]))
        end
    end
end

---@async
---@param packages string[] @The Gem packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return function()
        return M.install(packages).with_receipt()
    end
end

---@async
---@param packages string[] @The Gem packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.install(packages)
    local ctx = installer.context()
    local pkgs = _.list_copy(packages or {})

    ctx.requested_version:if_present(function(version)
        pkgs[1] = ("%s:%s"):format(pkgs[1], version)
    end)

    ctx.spawn.gem {
        "install",
        "--no-user-install",
        "--install-dir=.",
        "--bindir=bin",
        "--no-document",
        pkgs,
    }

    return {
        with_receipt = with_receipt(packages),
    }
end

---@alias GemOutdatedPackage {name:string, current_version: string, latest_version: string}

---Parses a string input like "package (0.1.0 < 0.2.0)" into its components
---@param outdated_gem string
---@return GemOutdatedPackage
function M.parse_outdated_gem(outdated_gem)
    local package_name, version_expression = outdated_gem:match "^(.+) %((.+)%)"
    if not package_name or not version_expression then
        -- unparseable
        return nil
    end
    local current_version, latest_version = unpack(vim.split(version_expression, "<"))

    ---@type GemOutdatedPackage
    local outdated_package = {
        name = vim.trim(package_name),
        current_version = vim.trim(current_version),
        latest_version = vim.trim(latest_version),
    }
    return outdated_package
end

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

local function not_empty(s)
    return s ~= nil and s ~= ""
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "gem" then
        return Result.failure "Receipt does not have a primary source of type gem"
    end
    return spawn.gem({ "outdated", cwd = install_dir, env = M.env(install_dir) }):map_catching(function(result)
        ---@type string[]
        local lines = vim.split(result.stdout, "\n")
        local outdated_gems = vim.tbl_map(M.parse_outdated_gem, vim.tbl_filter(not_empty, lines))

        local outdated_gem = _.find_first(function(gem)
            return gem.name == receipt.primary_source.package and gem.current_version ~= gem.latest_version
        end, outdated_gems)

        return Optional.of_nilable(outdated_gem)
            :map(function(gem)
                return {
                    name = receipt.primary_source.package,
                    current_version = assert(gem.current_version),
                    latest_version = assert(gem.latest_version),
                }
            end)
            :or_else_throw "Primary package is not outdated."
    end)
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    return spawn.gem({
        "list",
        cwd = install_dir,
        env = M.env(install_dir),
    }):map_catching(function(result)
        local gems = M.parse_gem_list_output(result.stdout)
        return Optional.of_nilable(gems[receipt.primary_source.package]):or_else_throw "Failed to find gem package version."
    end)
end

---@param install_dir string
function M.env(install_dir)
    return {
        GEM_HOME = install_dir,
        GEM_PATH = install_dir,
        PATH = process.extend_path { path.concat { install_dir, "bin" } },
    }
end

return M
