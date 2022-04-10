local process = require "nvim-lsp-installer.process"
local path = require "nvim-lsp-installer.path"
local spawn = require "nvim-lsp-installer.core.spawn"
local a = require "nvim-lsp-installer.core.async"
local Optional = require "nvim-lsp-installer.core.optional"
local crates = require "nvim-lsp-installer.core.clients.crates"
local Result = require "nvim-lsp-installer.core.result"
local installer = require "nvim-lsp-installer.core.installer"

local fetch_crate = a.promisify(crates.fetch_crate, true)

---@param crate string
local function with_receipt(crate)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.cargo(crate))
    end
end

local M = {}

---@async
---@param crate string The crate to install.
---@param opts {git:boolean, features:string|nil}
function M.crate(crate, opts)
    return function()
        return M.install(crate, opts).with_receipt()
    end
end

---@async
---@param crate string The crate to install.
---@param opts {git:boolean, features:string|nil}
function M.install(crate, opts)
    local ctx = installer.context()
    opts = opts or {}
    ctx.requested_version:if_present(function()
        assert(not opts.git, "Providing a version when installing a git crate is not allowed.")
    end)

    ctx.spawn.cargo {
        "install",
        "--root",
        ".",
        "--locked",
        ctx.requested_version
            :map(function(version)
                return { "--version", version }
            end)
            :or_else(vim.NIL),
        opts.features and { "--features", opts.features } or vim.NIL,
        opts.git and { "--git", crate } or crate,
    }

    return {
        with_receipt = with_receipt(crate),
    }
end

---@param output string @The `cargo install --list` output.
---@return Record<string, string> @Key is the crate name, value is its version.
function M.parse_installed_crates(output)
    local installed_crates = {}
    for _, line in ipairs(vim.split(output, "\n")) do
        local name, version = line:match "^(.+)%s+v([.%S]+)[%s:]"
        if name and version then
            installed_crates[name] = version
        end
    end
    return installed_crates
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    local installed_version = M.get_installed_primary_package_version(receipt, install_dir):get_or_throw()

    local response = fetch_crate(receipt.primary_source.package)
    if installed_version ~= response.crate.max_stable_version then
        return Result.success {
            name = receipt.primary_source.package,
            current_version = installed_version,
            latest_version = response.crate.max_stable_version,
        }
    else
        return Result.failure "Primary package is not outdated."
    end
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    return spawn.cargo({
        "install",
        "--list",
        "--root",
        ".",
        cwd = install_dir,
    }):map_catching(function(result)
        local installed_crates = M.parse_installed_crates(result.stdout)
        if vim.in_fast_event() then
            a.scheduler() -- needed because vim.fn.* call
        end
        local package = vim.fn.fnamemodify(receipt.primary_source.package, ":t")
        return Optional.of_nilable(installed_crates[package]):or_else_throw "Failed to find cargo package version."
    end)
end

---@param install_dir string
function M.env(install_dir)
    return {
        PATH = process.extend_path { path.concat { install_dir, "bin" } },
    }
end

return M
