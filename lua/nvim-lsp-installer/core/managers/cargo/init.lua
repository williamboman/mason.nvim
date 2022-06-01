local process = require "nvim-lsp-installer.core.process"
local path = require "nvim-lsp-installer.core.path"
local spawn = require "nvim-lsp-installer.core.spawn"
local a = require "nvim-lsp-installer.core.async"
local Optional = require "nvim-lsp-installer.core.optional"
local installer = require "nvim-lsp-installer.core.installer"
local client = require "nvim-lsp-installer.core.managers.cargo.client"

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

    local final_crate = crate

    if opts.git then
        final_crate = { "--git" }
        if type(opts.git) == "string" then
            table.insert(final_crate, opts.git)
        end
        table.insert(final_crate, crate)
    end

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
        final_crate,
    }

    return {
        with_receipt = with_receipt(crate),
    }
end

---@param output string @The `cargo install --list` output.
---@return table<string, string> @Key is the crate name, value is its version.
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
    return M.get_installed_primary_package_version(receipt, install_dir):map_catching(function(installed_version)
        ---@type CrateResponse
        local crate_response = client.fetch_crate(receipt.primary_source.package):get_or_throw()
        if installed_version ~= crate_response.crate.max_stable_version then
            return {
                name = receipt.primary_source.package,
                current_version = installed_version,
                latest_version = crate_response.crate.max_stable_version,
            }
        else
            error "Primary package is not outdated."
        end
    end)
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
