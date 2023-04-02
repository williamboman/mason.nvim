local _ = require "mason-core.functional"

local function Mason()
    require("mason.ui").open()
end

vim.api.nvim_create_user_command("Mason", Mason, {
    desc = "Opens mason's UI window.",
    nargs = 0,
})

-- This is needed because neovim doesn't do any validation of command args when using custom completion (I think?)
local filter_valid_packages = _.filter(function(pkg_specifier)
    local notify = require "mason-core.notify"
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

---@param handles InstallHandle[]
local function join_handles(handles)
    local a = require "mason-core.async"
    local Optional = require "mason-core.optional"

    _.each(
        ---@param handle InstallHandle
        function(handle)
            handle:on("stdout", vim.schedule_wrap(vim.api.nvim_out_write))
            handle:on("stderr", vim.schedule_wrap(vim.api.nvim_err_write))
        end,
        handles
    )

    a.run_blocking(function()
        a.wait_all(_.map(
            ---@param handle InstallHandle
            function(handle)
                return function()
                    a.wait(function(resolve)
                        if handle:is_closed() then
                            resolve()
                        else
                            handle:once("closed", resolve)
                        end
                    end)
                end
            end,
            handles
        ))
        local failed_packages = _.filter_map(function(handle)
            -- TODO: The outcome of a package installation is currently not captured in the handle, but is instead
            -- internalized in the Package instance itself. Change this to assert on the handle state when it's
            -- available.
            if not handle.package:is_installed() then
                return Optional.of(handle.package.name)
            else
                return Optional.empty()
            end
        end, handles)

        if _.length(failed_packages) > 0 then
            a.wait(vim.schedule) -- wait for scheduler for logs to finalize
            a.wait(vim.schedule) -- logs have been written
            vim.api.nvim_err_writeln ""
            vim.api.nvim_err_writeln(
                ("The following packages failed to install: %s"):format(_.join(", ", failed_packages))
            )
            vim.cmd [[1cq]]
        end
    end)
end

---@param package_specifiers string[]
---@param opts? PackageInstallOpts
local function MasonInstall(package_specifiers, opts)
    opts = opts or {}
    local Package = require "mason-core.package"
    local registry = require "mason-registry"
    local is_headless = #vim.api.nvim_list_uis() == 0

    local install_packages = _.map(function(pkg_specifier)
        local package_name, version = Package.Parse(pkg_specifier)
        local pkg = registry.get_package(package_name)
        return pkg:install {
            version = version,
            debug = opts.debug,
            force = opts.force,
            target = opts.target,
        }
    end)

    if is_headless then
        registry.refresh()
        local valid_packages = filter_valid_packages(package_specifiers)
        if #valid_packages ~= #package_specifiers then
            -- When executing in headless mode we don't allow any of the provided packages to be invalid.
            -- This is to avoid things like scripts silently not erroring even if they've provided one or more invalid packages.
            return vim.cmd [[1cq]]
        end
        join_handles(install_packages(valid_packages))
    else
        local ui = require "mason.ui"
        ui.open()
        -- Important: We start installation of packages _after_ opening the UI. This gives the UI components a chance to
        -- register the necessary event handlers in time, avoiding desynced state.
        registry.refresh(function()
            local valid_packages = filter_valid_packages(package_specifiers)
            install_packages(valid_packages)
            vim.schedule(function()
                ui.set_sticky_cursor "installing-section"
            end)
        end)
    end
end

local parse_opts = _.compose(
    _.from_pairs,
    _.map(_.compose(function(arg)
        if #arg == 2 then
            return arg
        else
            return { arg[1], true }
        end
    end, _.split "=", _.gsub("^%-%-", "")))
)

---@param args string[]
---@return table<string, true|string> opts, string[] args
local function parse_args(args)
    local opts_list, args = unpack(_.partition(_.starts_with "--", args))
    local opts = parse_opts(opts_list)
    return opts, args
end

vim.api.nvim_create_user_command("MasonInstall", function(opts)
    local command_opts, packages = parse_args(opts.fargs)
    MasonInstall(packages, command_opts)
end, {
    desc = "Install one or more packages.",
    nargs = "+",
    complete = "custom,v:lua.mason_completion.available_package_completion",
})

---@param package_names string[]
local function MasonUninstall(package_names)
    local registry = require "mason-registry"
    local valid_packages = filter_valid_packages(package_names)
    if #valid_packages > 0 then
        _.each(function(package_name)
            local pkg = registry.get_package(package_name)
            pkg:uninstall()
        end, valid_packages)
        require("mason.ui").open()
    end
end

vim.api.nvim_create_user_command("MasonUninstall", function(opts)
    MasonUninstall(opts.fargs)
end, {
    desc = "Uninstall one or more packages.",
    nargs = "+",
    complete = "custom,v:lua.mason_completion.installed_package_completion",
})

local function MasonUninstallAll()
    local registry = require "mason-registry"
    require("mason.ui").open()
    for _, pkg in ipairs(registry.get_installed_packages()) do
        pkg:uninstall()
    end
end

vim.api.nvim_create_user_command("MasonUninstallAll", MasonUninstallAll, {
    desc = "Uninstall all packages.",
})

local function MasonUpdate()
    local notify = require "mason-core.notify"
    local registry = require "mason-registry"
    notify "Updating registries…"
    registry.update(vim.schedule_wrap(function(success, updated_registries)
        if success then
            local count = #updated_registries
            notify(("Successfully updated %d %s."):format(count, count == 1 and "registry" or "registries"))
        else
            notify(("Failed to update registries: %s"):format(updated_registries), vim.log.levels.ERROR)
        end
    end))
end

vim.api.nvim_create_user_command("MasonUpdate", MasonUpdate, {
    desc = "Update Mason registries.",
})

local function MasonLog()
    local log = require "mason-core.log"
    vim.cmd(([[tabnew %s]]):format(log.outfile))
end

vim.api.nvim_create_user_command("MasonLog", MasonLog, {
    desc = "Opens the mason.nvim log.",
})

-- selene: allow(global_usage)
_G.mason_completion = {
    available_package_completion = function()
        local registry = require "mason-registry"
        registry.refresh()
        local package_names = registry.get_all_package_names()
        table.sort(package_names)
        return table.concat(package_names, "\n")
    end,
    installed_package_completion = function()
        local registry = require "mason-registry"
        registry.refresh()
        local package_names = registry.get_installed_package_names()
        table.sort(package_names)
        return table.concat(package_names, "\n")
    end,
}

return {
    Mason = Mason,
    MasonInstall = MasonInstall,
    MasonUninstall = MasonUninstall,
    MasonUninstallAll = MasonUninstallAll,
    MasonUpdate = MasonUpdate,
    MasonLog = MasonLog,
}
