local installer = require "nvim-lsp-installer.core.installer"
local process = require "nvim-lsp-installer.core.process"
local platform = require "nvim-lsp-installer.core.platform"
local spawn = require "nvim-lsp-installer.core.spawn"
local a = require "nvim-lsp-installer.core.async"
local Optional = require "nvim-lsp-installer.core.optional"

local M = {}

---@param packages string[]
local function with_receipt(packages)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.go(packages[1]))
        -- Install secondary packages
        for i = 2, #packages do
            local package = packages[i]
            ctx.receipt:with_secondary_source(ctx.receipt.go(package))
        end
    end
end

---@async
---@param packages string[] The Go packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
function M.packages(packages)
    return function()
        M.install(packages).with_receipt()
    end
end

---@async
---@param packages string[] The Go packages to install. The first item in this list will be the recipient of the server version, should the user request a specific one.
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

    return {
        with_receipt = with_receipt(packages),
    }
end

---@param output string @The output from `go version -m` command.
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

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if vim.in_fast_event() then
        a.scheduler()
    end
    -- trims e.g. golang.org/x/tools/gopls to gopls
    local executable = vim.fn.fnamemodify(receipt.primary_source.package, ":t")
    return spawn.go({
        "version",
        "-m",
        platform.is_win and ("%s.exe"):format(executable) or executable,
        cwd = install_dir,
    }):map_catching(function(result)
        local parsed_output = M.parse_mod_version_output(result.stdout)
        return Optional.of_nilable(parsed_output.mod[receipt.primary_source.package]):or_else_throw "Failed to parse mod version"
    end)
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    return spawn.go({
        "list",
        "-json",
        "-m",
        ("%s@latest"):format(receipt.primary_source.package),
        cwd = install_dir,
    }):map_catching(function(result)
        ---@type {Path: string, Version: string}
        local output = vim.json.decode(result.stdout)
        return Optional.of_nilable(output.Version)
            :map(function(latest_version)
                local installed_version = M.get_installed_primary_package_version(receipt, install_dir):get_or_throw()
                if installed_version ~= latest_version then
                    return {
                        name = receipt.primary_source.package,
                        current_version = assert(installed_version),
                        latest_version = assert(latest_version),
                    }
                end
            end)
            :or_else_throw "Primary package is not outdated."
    end)
end

---@param install_dir string
function M.env(install_dir)
    return {
        PATH = process.extend_path { install_dir },
    }
end

return M
