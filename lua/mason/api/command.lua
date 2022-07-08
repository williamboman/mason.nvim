local M = {}

vim.api.nvim_create_user_command("Mason", function()
    require("mason.ui").open()
end, {
    desc = "Opens mason's UI window.",
    nargs = 0,
})

vim.api.nvim_create_user_command("MasonInstall", function(opts)
    local Package = require "mason-core.package"
    local registry = require "mason-registry"
    for _, package_specifier in ipairs(opts.fargs) do
        local package_name, version = Package.Parse(package_specifier)
        local pkg = registry.get_package(package_name)
        pkg:install { version = version }
    end
    require("mason.ui").open()
end, {
    desc = "Install one or more packages.",
    nargs = "+",
    complete = "custom,v:lua.mason_completion.available_package_completion",
})

vim.api.nvim_create_user_command("MasonUninstall", function(opts)
    local registry = require "mason-registry"
    for _, package_name in ipairs(opts.fargs) do
        local pkg = registry.get_package(package_name)
        pkg:uninstall()
    end
    require("mason.ui").open()
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
