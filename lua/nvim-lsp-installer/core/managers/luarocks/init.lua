local installer = require "nvim-lsp-installer.core.installer"
local _ = require "nvim-lsp-installer.core.functional"
local process = require "nvim-lsp-installer.core.process"
local path = require "nvim-lsp-installer.core.path"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"
local Optional = require "nvim-lsp-installer.core.optional"

local M = {}

---@param package string
local function with_receipt(package)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.luarocks(package))
    end
end

---@param package string @The luarock package to install.
---@param opts {dev: boolean}|nil
function M.package(package, opts)
    return function()
        return M.install(package, opts).with_receipt()
    end
end

---@async
---@param package string @The luarock package to install.
---@param opts {dev: boolean}|nil
function M.install(package, opts)
    opts = opts or {}
    local ctx = installer.context()
    ctx:promote_cwd()
    ctx.spawn.luarocks {
        "install",
        "--tree",
        ctx.cwd:get(),
        opts.dev and "--dev" or vim.NIL,
        package,
        ctx.requested_version:or_else(vim.NIL),
    }
    return {
        with_receipt = with_receipt(package),
    }
end

---@alias InstalledLuarock {package: string, version: string, arch: string, nrepo: string, namespace: string}

---@type fun(output: string): InstalledLuarock[]
M.parse_installed_rocks = _.compose(
    _.map(_.compose(
        -- https://github.com/luarocks/luarocks/blob/fbd3566a312e647cde57b5d774533731e1aa844d/src/luarocks/search.lua#L317
        _.zip_table { "package", "version", "arch", "nrepo", "namespace" },
        _.split "\t"
    )),
    _.split "\n"
)

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if receipt.primary_source.type ~= "luarocks" then
        return Result.failure "Receipt does not have a primary source of type luarocks"
    end
    local primary_package = receipt.primary_source.package
    return spawn.luarocks({
        "list",
        "--tree",
        install_dir,
        "--porcelain",
    }):map_catching(function(result)
        local luarocks = M.parse_installed_rocks(result.stdout)
        return Optional.of_nilable(_.find_first(_.prop_eq("package", primary_package), luarocks))
            :map(_.prop "version")
            :or_else_throw()
    end)
end

---@alias OutdatedLuarock {name: string, installed: string, available: string, repo: string}

---@type fun(output: string): OutdatedLuarock[]
M.parse_outdated_rocks = _.compose(
    _.map(_.compose(
        -- https://github.com/luarocks/luarocks/blob/fbd3566a312e647cde57b5d774533731e1aa844d/src/luarocks/cmd/list.lua#L59
        _.zip_table { "name", "installed", "available", "repo" },
        _.split "\t"
    )),
    _.split "\n"
)

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "luarocks" then
        return Result.failure "Receipt does not have a primary source of type luarocks"
    end
    local primary_package = receipt.primary_source.package
    return spawn.luarocks({
        "list",
        "--outdated",
        "--tree",
        install_dir,
        "--porcelain",
    }):map_catching(function(result)
        local outdated_rocks = M.parse_outdated_rocks(result.stdout)
        return Optional.of_nilable(_.find_first(_.prop_eq("name", primary_package), outdated_rocks))
            :map(
                ---@param outdated_rock OutdatedLuarock
                function(outdated_rock)
                    return {
                        name = outdated_rock.name,
                        current_version = assert(outdated_rock.installed),
                        latest_version = assert(outdated_rock.available),
                    }
                end
            )
            :or_else_throw()
    end)
end

---@param install_dir string
function M.env(install_dir)
    return {
        PATH = process.extend_path { path.concat { install_dir, "bin" } },
    }
end

return M
