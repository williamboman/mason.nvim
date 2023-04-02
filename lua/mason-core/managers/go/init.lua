local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"
local a = require "mason-core.async"
local installer = require "mason-core.installer"
local platform = require "mason-core.platform"
local spawn = require "mason-core.spawn"

local M = {}

local create_bin_path = _.if_else(_.always(platform.is.win), _.format "%s.exe", _.identity)

---@param packages string[]
local function with_receipt(packages)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.go(packages[1]))
        -- Install secondary packages
        for i = 2, #packages do
            local pkg = packages[i]
            ctx.receipt:with_secondary_source(ctx.receipt.go(pkg))
        end
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The go packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.packages(packages)
    return function()
        M.install(packages).with_receipt()
    end
end

---@async
---@param packages { [number]: string, bin: string[]? } The go packages to install. The first item in this list will be the recipient of the requested version, if set.
function M.install(packages)
    local ctx = installer.context()
    local env = {
        GOBIN = ctx.cwd:get(),
    }
    -- Install the head package
    do
        local head_package = packages[1]
        local version = ctx.requested_version:or_else "latest"
        ctx.spawn.go {
            "install",
            "-v",
            ("%s@%s"):format(head_package, version),
            env = env,
        }
    end

    -- Install secondary packages
    for i = 2, #packages do
        ctx.spawn.go { "install", "-v", ("%s@latest"):format(packages[i]), env = env }
    end

    if packages.bin then
        _.each(function(executable)
            ctx:link_bin(executable, create_bin_path(executable))
        end, packages.bin)
    end

    return {
        with_receipt = with_receipt(packages),
    }
end

---@param output string The output from `go version -m` command.
function M.parse_mod_version_output(output)
    ---@type {path: string[], mod: string[], dep: string[], build: string[]}
    local result = {}
    local lines = vim.split(output, "\n")
    for _, line in ipairs { unpack(lines, 2) } do
        local type, id, value = unpack(vim.split(line, "%s+", { trimempty = true }))
        if type and id then
            result[type] = result[type] or {}
            result[type][id] = value or ""
        end
    end
    return result
end

local trim_wildcard_suffix = _.gsub("/%.%.%.$", "")

---@param pkg string
function M.parse_package_mod(pkg)
    if _.starts_with("github.com", pkg) then
        local components = _.split("/", pkg)
        return trim_wildcard_suffix(_.join("/", {
            components[1], -- github.com
            components[2], -- owner
            components[3], -- repo
        }))
    elseif _.starts_with("golang.org", pkg) then
        local components = _.split("/", pkg)
        return trim_wildcard_suffix(_.join("/", {
            components[1], -- golang.org
            components[2], -- x
            components[3], -- owner
            components[4], -- repo
        }))
    else
        -- selene: allow(if_same_then_else)
        local components = _.split("/", pkg)
        return trim_wildcard_suffix(_.join("/", {
            components[1],
            components[2],
            components[3],
        }))
    end
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    a.scheduler()
    local normalized_pkg_name = trim_wildcard_suffix(receipt.primary_source.package)
    -- trims e.g. golang.org/x/tools/gopls to gopls
    local executable = vim.fn.fnamemodify(normalized_pkg_name, ":t")
    return spawn
        .go({
            "version",
            "-m",
            platform.is.win and ("%s.exe"):format(executable) or executable,
            cwd = install_dir,
        })
        :map_catching(function(result)
            local parsed_output = M.parse_mod_version_output(result.stdout)
            return Optional.of_nilable(parsed_output.mod[M.parse_package_mod(receipt.primary_source.package)])
                :or_else_throw "Failed to parse mod version"
        end)
end

---@async
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    local normalized_pkg_name = M.parse_package_mod(receipt.primary_source.package)
    return spawn
        .go({
            "list",
            "-json",
            "-m",
            ("%s@latest"):format(normalized_pkg_name),
            cwd = install_dir,
        })
        :map_catching(function(result)
            ---@type {Path: string, Version: string}
            local output = vim.json.decode(result.stdout)
            return Optional.of_nilable(output.Version)
                :map(function(latest_version)
                    local installed_version = M.get_installed_primary_package_version(receipt, install_dir)
                        :get_or_throw()
                    if installed_version ~= latest_version then
                        return {
                            name = normalized_pkg_name,
                            current_version = assert(installed_version, "missing installed_version"),
                            latest_version = assert(latest_version, "missing latest_version"),
                        }
                    end
                end)
                :or_else_throw "Primary package is not outdated."
        end)
end

return M
