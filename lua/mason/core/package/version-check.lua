local Result = require "mason.core.result"
local cargo = require "mason.core.managers.cargo"
local composer = require "mason.core.managers.composer"
local eclipse = require "mason.core.clients.eclipse"
local gem = require "mason.core.managers.gem"
local git = require "mason.core.managers.git"
local github = require "mason.core.managers.github"
local go = require "mason.core.managers.go"
local luarocks = require "mason.core.managers.luarocks"
local npm = require "mason.core.managers.npm"
local pip3 = require "mason.core.managers.pip3"

---@param field_name string
local function version_in_receipt(field_name)
    ---@param receipt InstallReceipt
    ---@return Result
    return function(receipt)
        return Result.success(receipt.primary_source[field_name])
    end
end

---@type table<InstallReceiptSourceType, async fun(receipt: InstallReceipt, install_dir: string): Result>
local get_installed_version_by_type = {
    ["npm"] = npm.get_installed_primary_package_version,
    ["pip3"] = pip3.get_installed_primary_package_version,
    ["gem"] = gem.get_installed_primary_package_version,
    ["cargo"] = cargo.get_installed_primary_package_version,
    ["composer"] = composer.get_installed_primary_package_version,
    ["git"] = git.get_installed_revision,
    ["go"] = go.get_installed_primary_package_version,
    ["luarocks"] = luarocks.get_installed_primary_package_version,
    ["github_release_file"] = version_in_receipt "release",
    ["github_release"] = version_in_receipt "release",
    ["github_tag"] = version_in_receipt "tag",
    ["jdtls"] = version_in_receipt "version",
}

---@async
---@param receipt InstallReceipt
local function jdtls_check(receipt)
    return eclipse.fetch_latest_jdtls_version():map_catching(function(latest_version)
        if receipt.primary_source.version ~= latest_version then
            return {
                name = "jdtls",
                current_version = receipt.primary_source.version,
                latest_version = latest_version,
            }
        end
        error "Primary package is not outdated."
    end)
end

---@class NewPackageVersion
---@field name string
---@field current_version string
---@field latest_version string

local get_new_version_by_type = {
    ["npm"] = npm.check_outdated_primary_package,
    ["pip3"] = pip3.check_outdated_primary_package,
    ["git"] = git.check_outdated_git_clone,
    ["cargo"] = cargo.check_outdated_primary_package,
    ["composer"] = composer.check_outdated_primary_package,
    ["gem"] = gem.check_outdated_primary_package,
    ["go"] = go.check_outdated_primary_package,
    ["luarocks"] = luarocks.check_outdated_primary_package,
    ["jdtls"] = jdtls_check,
    ["github_release_file"] = github.check_outdated_primary_package_release,
    ["github_release"] = github.check_outdated_primary_package_release,
    ["github_tag"] = github.check_outdated_primary_package_tag,
}

---@param provider_mapping table<string, async fun(receipt: InstallReceipt, install_dir: string)>: Result
local function version_check(provider_mapping)
    ---@param receipt InstallReceipt
    ---@param install_dir string
    return function(receipt, install_dir)
        local check = provider_mapping[receipt.primary_source.type]
        if not check then
            return Result.failure(
                ("Packages installed via %s does not yet support version check."):format(receipt.primary_source.type)
            )
        end
        return check(receipt, install_dir)
    end
end

return {
    get_installed_version = version_check(get_installed_version_by_type),
    get_new_version = version_check(get_new_version_by_type),
}
