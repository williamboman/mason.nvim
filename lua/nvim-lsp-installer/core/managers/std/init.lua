local a = require "nvim-lsp-installer.core.async"
local installer = require "nvim-lsp-installer.core.installer"
local fetch = require "nvim-lsp-installer.core.fetch"
local platform = require "nvim-lsp-installer.core.platform"
local powershell = require "nvim-lsp-installer.core.managers.powershell"
local path = require "nvim-lsp-installer.core.path"
local Result = require "nvim-lsp-installer.core.result"

local M = {}

local function with_system_executable_receipt(executable)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.system(executable))
    end
end

---@async
---@param executable string
---@param opts {help_url:string|nil}
function M.system_executable(executable, opts)
    return function()
        M.ensure_executable(executable, opts).with_receipt()
    end
end

---@async
---@param executable string
---@param opts {help_url:string|nil}
function M.ensure_executable(executable, opts)
    local ctx = installer.context()
    opts = opts or {}
    if vim.in_fast_event() then
        a.scheduler()
    end
    if vim.fn.executable(executable) ~= 1 then
        ctx.stdio_sink.stderr(("%s was not found in path.\n"):format(executable))
        if opts.help_url then
            ctx.stdio_sink.stderr(("See %s for installation instructions.\n"):format(opts.help_url))
        end
        error("Installation failed: system executable was not found.", 0)
    end

    return {
        with_receipt = with_system_executable_receipt(executable),
    }
end

---@async
---@param url string
---@param out_file string
function M.download_file(url, out_file)
    local ctx = installer.context()
    ctx.stdio_sink.stdout(("Downloading file %q...\n"):format(url))
    fetch(url, {
        out_file = path.concat { ctx.cwd:get(), out_file },
    })
        :map_err(function(err)
            return ("Failed to download file %q.\n%s"):format(url, err)
        end)
        :get_or_throw()
end

---@async
---@param file string
---@param dest string
function M.unzip(file, dest)
    local ctx = installer.context()
    platform.when {
        unix = function()
            ctx.spawn.unzip { "-d", dest, file }
        end,
        win = function()
            powershell.command(
                ("Microsoft.PowerShell.Archive\\Expand-Archive -Path %q -DestinationPath %q"):format(file, dest),
                {},
                ctx.spawn
            )
        end,
    }
    pcall(function()
        -- make sure the .zip archive doesn't linger
        ctx.fs:unlink(file)
    end)
end

---@param file string
local function win_extract(file)
    local ctx = installer.context()
    Result.run_catching(function()
        ctx.spawn["7z"] { "x", "-y", "-r", file }
    end)
        :recover_catching(function()
            ctx.spawn.peazip { "-ext2here", path.concat { ctx.cwd:get(), file } } -- peazip requires absolute paths
        end)
        :recover_catching(function()
            ctx.spawn.wzunzip { file }
        end)
        :recover_catching(function()
            ctx.spawn.winrar { "e", file }
        end)
        :get_or_throw(("Unable to unpack %s."):format(file))
end

---@async
---@param file string
---@param opts {strip_components:integer}
function M.untar(file, opts)
    opts = opts or {}
    local ctx = installer.context()
    ctx.spawn.tar {
        opts.strip_components and { "--strip-components", opts.strip_components } or vim.NIL,
        "-xvf",
        file,
    }
    pcall(function()
        ctx.fs:unlink(file)
    end)
end

---@async
---@param file string
---@param opts {strip_components:integer}
function M.untarxz(file, opts)
    opts = opts or {}
    local ctx = installer.context()
    platform.when {
        unix = function()
            M.untar(file, opts)
        end,
        win = function()
            Result.run_catching(function()
                win_extract(file) -- unpack .tar.xz to .tar
                local uncompressed_tar = file:gsub(".xz$", "")
                M.untar(uncompressed_tar, opts)
            end):recover(function()
                ctx.spawn.arc {
                    "unarchive",
                    opts.strip_components and { "--strip-components", opts.strip_components } or vim.NIL,
                    file,
                }
                pcall(function()
                    ctx.fs:unlink(file)
                end)
            end)
        end,
    }
end

---@async
---@param file string
function M.gunzip(file)
    platform.when {
        unix = function()
            local ctx = installer.context()
            ctx.spawn.gzip { "-d", file }
        end,
        win = function()
            win_extract(file)
        end,
    }
end

---@async
---@param flags string @The chmod flag to apply.
---@param files string[] @A list of relative paths to apply the chmod on.
function M.chmod(flags, files)
    if platform.is_unix then
        local ctx = installer.context()
        ctx.spawn.chmod { flags, files }
    end
end

---@async
---Wrapper around vim.ui.select.
---@param items table
---@params opts
function M.select(items, opts)
    assert(not platform.is_headless, "Tried to prompt for user input while in headless mode.")
    if vim.in_fast_event() then
        a.scheduler()
    end
    local async_select = a.promisify(vim.ui.select)
    return async_select(items, opts)
end

return M
