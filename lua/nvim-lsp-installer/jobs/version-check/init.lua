local Result = require "nvim-lsp-installer.core.result"
local npm = require "nvim-lsp-installer.core.managers.npm"
local cargo = require "nvim-lsp-installer.core.managers.cargo"
local pip3 = require "nvim-lsp-installer.core.managers.pip3"
local gem = require "nvim-lsp-installer.core.managers.gem"
local go = require "nvim-lsp-installer.core.managers.go"
local luarocks = require "nvim-lsp-installer.core.managers.luarocks"
local git = require "nvim-lsp-installer.core.managers.git"
local composer = require "nvim-lsp-installer.core.managers.composer"

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

---@type table<InstallReceiptSourceType, async fun(server: Server, receipt: InstallReceipt): Result>
local version_checker = {
    ["npm"] = function(server, receipt)
        return npm.get_installed_primary_package_version(receipt, server.root_dir)
    end,
    ["pip3"] = function(server, receipt)
        return pip3.get_installed_primary_package_version(receipt, server.root_dir)
    end,
    ["gem"] = function(server, receipt)
        return gem.get_installed_primary_package_version(receipt, server.root_dir)
    end,
    ["cargo"] = function(server, receipt)
        return cargo.get_installed_primary_package_version(receipt, server.root_dir)
    end,
    ["composer"] = function(server, receipt)
        return composer.get_installed_primary_package_version(receipt, server.root_dir)
    end,
    ["git"] = function(server)
        return git.get_installed_revision(server.root_dir)
    end,
    ["go"] = function(server, receipt)
        return go.get_installed_primary_package_version(receipt, server.root_dir)
    end,
    ["luarocks"] = function(server, receipt)
        return luarocks.get_installed_primary_package_version(receipt, server.root_dir)
    end,
    ["github_release_file"] = version_in_receipt "release",
    ["github_release"] = version_in_receipt "release",
    ["github_tag"] = version_in_receipt "tag",
    ["jdtls"] = version_in_receipt "version",
}

---@async
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
