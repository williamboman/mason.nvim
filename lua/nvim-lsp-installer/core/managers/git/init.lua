local spawn = require "nvim-lsp-installer.core.spawn"
local Result = require "nvim-lsp-installer.core.result"
local installer = require "nvim-lsp-installer.core.installer"
local _ = require "nvim-lsp-installer.core.functional"

local M = {}

---@param repo string
local function with_receipt(repo)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.git_remote(repo))
    end
end

---@async
---@param opts {[1]: string, recursive: boolean, version: Optional|nil} @The first item in the table is the repository to clone.
function M.clone(opts)
    local ctx = installer.context()
    local repo = assert(opts[1], "No git URL provided.")
    ctx.spawn.git {
        "clone",
        "--depth",
        "1",
        opts.recursive and "--recursive" or vim.NIL,
        repo,
        ".",
    }
    _.coalesce(opts.version, ctx.requested_version):if_present(function(version)
        ctx.spawn.git { "fetch", "--depth", "1", "origin", version }
        ctx.spawn.git { "checkout", "FETCH_HEAD" }
    end)

    return {
        with_receipt = with_receipt(repo),
    }
end

---@async
---@param receipt InstallReceipt
---@param install_dir string
function M.check_outdated_git_clone(receipt, install_dir)
    if receipt.primary_source.type ~= "git" then
        return Result.failure "Receipt does not have a primary source of type git"
    end
    return spawn.git({ "fetch", "origin", "HEAD", cwd = install_dir }):map_catching(function()
        local result = spawn.git({ "rev-parse", "FETCH_HEAD", "HEAD", cwd = install_dir }):get_or_throw()
        local remote_head, local_head = unpack(vim.split(result.stdout, "\n"))
        if remote_head == local_head then
            error("Git clone is up to date.", 2)
        end
        return {
            name = receipt.primary_source.remote,
            current_version = assert(local_head),
            latest_version = assert(remote_head),
        }
    end)
end

---@async
---@param install_dir string
function M.get_installed_revision(install_dir)
    return spawn.git({
        "rev-parse",
        "--short",
        "HEAD",
        cwd = install_dir,
    }):map_catching(function(result)
        return assert(vim.trim(result.stdout))
    end)
end

return M
