local notify = require "mason-core.notify"
local _ = require "mason-core.functional"

local M = {}

vim.api.nvim_create_user_command("Mason", function()
    require("mason.ui").open()
end, {
    desc = "Opens mason's UI window.",
    nargs = 0,
})

-- This is needed because neovim doesn't do any validation of command args when using custom completion (I think?)
local filter_valid_packages = _.filter(function(pkg_specifier)
    local Package = require "mason-core.package"
    local registry = require "mason-registry"
    local package_name = Package.Parse(pkg_specifier)
    local ok = pcall(registry.get_package, package_name)
    if ok then
        return true
    else
        notify(("%q is not a valid package."):format(pkg_specifier), vim.log.levels.ERROR)
        return false
    end
end)

vim.api.nvim_create_user_command("MasonInstall", function(opts)
    local Package = require "mason-core.package"
    local registry = require "mason-registry"
    local valid_packages = filter_valid_packages(opts.fargs)
    if #valid_packages > 0 then
        _.each(function(pkg_specifier)
            local package_name, version = Package.Parse(pkg_specifier)
            local pkg = registry.get_package(package_name)
            pkg:install { version = version }
        end, valid_packages)
        require("mason.ui").open()
    end
end, {
    desc = "Install one or more packages.",
    nargs = "+",
    complete = "custom,v:lua.mason_completion.available_package_completion",
})

vim.api.nvim_create_user_command("MasonUninstall", function(opts)
    local registry = require "mason-registry"
    local valid_packages = filter_valid_packages(opts.fargs)
    if #valid_packages > 0 then
        _.each(function(package_name)
            local pkg = registry.get_package(package_name)
            pkg:uninstall()
        end, filter_valid_packages)
        require("mason.ui").open()
    end
end, {
    desc = "Uninstall one or more packages.",
    nargs = "+",
    complete = "custom,v:lua.mason_completion.installed_package_completion",
})

vim.api.nvim_create_user_command("MasonUninstallAll", function()
    local registry = require "mason-registry"
    require("mason.ui").open()
    for _, pkg in ipairs(registry.get_installed_packages()) do
        pkg:uninstall()
    end
end, {
    desc = "Uninstall all packages.",
})

vim.api.nvim_create_user_command("MasonLog", function()
    local log = require "mason-core.log"
    vim.cmd(([[tabnew %s]]):format(log.outfile))
end, {
    desc = "Opens the mason.nvim log.",
})

_G.mason_completion = {
    available_package_completion = function()
        local registry = require "mason-registry"
        local package_names = registry.get_all_package_names()
        table.sort(package_names)
        return table.concat(package_names, "\n")
    end,
    installed_package_completion = function()
        local registry = require "mason-registry"
        local package_names = registry.get_installed_package_names()
        table.sort(package_names)
        return table.concat(package_names, "\n")
    end,
}

return M
