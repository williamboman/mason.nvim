local Optional = require "mason-core.optional"
local Result = require "mason-core.result"
local _ = require "mason-core.functional"
local installer = require "mason-core.installer"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local spawn = require "mason-core.spawn"

local M = {}

local create_bin_path = _.compose(path.concat, function(executable)
    return _.append(executable, { "bin" })
end, _.if_else(_.always(platform.is.win), _.format "%s.bat", _.identity))

---@param package string
local function with_receipt(package)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.luarocks(package))
    end
end

---@param package string The luarock package to install.
---@param opts { dev: boolean?, server: string?, bin: string[]? }?
function M.package(package, opts)
    return function()
        return M.install(package, opts).with_receipt()
    end
end

---@async
---@param pkg string: The luarock package to install.
---@param opts { dev: boolean?, server: string?, bin: string[]? }?
function M.install(pkg, opts)
    opts = opts or {}
    local ctx = installer.context()
    ctx:promote_cwd()
    ctx.spawn.luarocks {
        "install",
        "--tree",
        ctx.cwd:get(),
        opts.dev and "--dev" or vim.NIL,
        opts.server and ("--server=%s"):format(opts.server) or vim.NIL,
        pkg,
        ctx.requested_version:or_else(vim.NIL),
    }
    if opts.bin then
        _.each(function(executable)
            ctx:link_bin(executable, create_bin_path(executable))
        end, opts.bin)
    end
    return {
        with_receipt = with_receipt(pkg),
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
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.get_installed_primary_package_version(receipt, install_dir)
    if receipt.primary_source.type ~= "luarocks" then
        return Result.failure "Receipt does not have a primary source of type luarocks"
    end
    local primary_package = receipt.primary_source.package
    return spawn
        .luarocks({
            "list",
            "--tree",
            install_dir,
            "--porcelain",
        })
        :map_catching(function(result)
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
---@param receipt InstallReceipt<InstallReceiptPackageSource>
---@param install_dir string
function M.check_outdated_primary_package(receipt, install_dir)
    if receipt.primary_source.type ~= "luarocks" then
        return Result.failure "Receipt does not have a primary source of type luarocks"
    end
    local primary_package = receipt.primary_source.package
    return spawn
        .luarocks({
            "list",
            "--outdated",
            "--tree",
            install_dir,
            "--porcelain",
        })
        :map_catching(function(result)
            local outdated_rocks = M.parse_outdated_rocks(result.stdout)
            return Optional.of_nilable(_.find_first(_.prop_eq("name", primary_package), outdated_rocks))
                :map(
                    ---@param outdated_rock OutdatedLuarock
                    function(outdated_rock)
                        return {
                            name = outdated_rock.name,
                            current_version = assert(outdated_rock.installed, "missing installed luarock version"),
                            latest_version = assert(outdated_rock.available, "missing available luarock version"),
                        }
                    end
                )
                :or_else_throw()
        end)
end

return M
