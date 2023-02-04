local path = require "mason-core.path"
local Result = require "mason-core.result"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local log = require "mason-core.log"
local fs = require "mason-core.fs"
local a = require "mason-core.async"

local M = {}

---@param receipt InstallReceipt
local function unlink_bin(receipt)
    local bin = receipt.links.bin
    if not bin then
        return
    end
    -- Windows executables did not include file extension in bin receipts on 1.0.
    local should_append_cmd = platform.is.win and receipt.schema_version == "1.0"
    for executable in pairs(bin) do
        if should_append_cmd then
            executable = executable .. ".cmd"
        end
        local bin_path = path.bin_prefix(executable)
        fs.sync.unlink(bin_path)
    end
end

---@param receipt InstallReceipt
local function unlink_share(receipt)
    local share = receipt.links.share
    if not share then
        return
    end
    for share_file in pairs(share) do
        local bin_path = path.share_prefix(share_file)
        fs.sync.unlink(bin_path)
    end
end

---@param pkg Package
---@param receipt InstallReceipt
function M.unlink(pkg, receipt)
    log.fmt_debug("Unlinking %s", pkg, receipt.links)
    unlink_bin(receipt)
    unlink_share(receipt)
end

---@async
---@param context InstallContext
local function link_bin(context)
    return Result.try(function(try)
        local links = context.links.bin
        local pkg = context.package
        for name, rel_path in pairs(links) do
            if platform.is.win then
                name = ("%s.cmd"):format(name)
            end
            local target_abs_path = path.concat { pkg:get_install_path(), rel_path }
            local bin_path = path.bin_prefix(name)

            if not context.opts.force and fs.async.file_exists(bin_path) then
                return Result.failure(("bin/%s is already linked."):format(name))
            end
            if not fs.async.file_exists(target_abs_path) then
                return Result.failure(("Link target %q does not exist."):format(target_abs_path))
            end

            log.fmt_debug("Linking bin %s to %s", name, target_abs_path)

            platform.when {
                unix = function()
                    try(Result.pcall(fs.async.symlink, target_abs_path, bin_path))
                end,
                win = function()
                    -- We don't "symlink" on Windows because:
                    -- 1) .LNK is not commonly found in PATHEXT
                    -- 2) some executables can only run from their true installation location
                    -- 3) many utilities only consider .COM, .EXE, .CMD, .BAT files as candidates by default when resolving executables (e.g. neovim's |exepath()| and |executable()|)
                    try(Result.pcall(
                        fs.async.write_file,
                        bin_path,
                        _.dedent(([[
                        @ECHO off
                        GOTO start
                        :find_dp0
                        SET dp0=%%~dp0
                        EXIT /b
                        :start
                        SETLOCAL
                        CALL :find_dp0

                        endLocal & goto #_undefined_# 2>NUL || title %%COMSPEC%% & "%s" %%*
                ]]):format(target_abs_path))
                    ))
                end,
            }
            context.receipt:with_link("bin", name, rel_path)
        end
    end)
end

---@async
---@param context InstallContext
local function link_share(context)
    return Result.try(function(try)
        for name, rel_path in pairs(context.links.share) do
            local dest = path.share_prefix(name)

            do
                if vim.in_fast_event() then
                    a.scheduler()
                end

                local dir = vim.fn.fnamemodify(dest, ":h")
                if not fs.async.dir_exists(dir) then
                    try(Result.pcall(fs.async.mkdirp, dir))
                end
            end

            local target_abs_path = path.concat { context.package:get_install_path(), rel_path }

            if context.opts.force then
                if fs.async.file_exists(dest) then
                    try(Result.pcall(fs.async.unlink, dest))
                end
            elseif fs.async.file_exists(dest) then
                return Result.failure(("share/%s is already linked."):format(name))
            end
            if not fs.async.file_exists(target_abs_path) then
                return Result.failure(("Link target %q does not exist."):format(target_abs_path))
            end

            try(Result.pcall(fs.async.symlink, target_abs_path, dest))
            context.receipt:with_link("share", name, rel_path)
        end
    end)
end

---@async
---@param context InstallContext
function M.link(context)
    log.fmt_debug("Linking %s", context.package)
    return Result.try(function(try)
        try(link_bin(context))
        try(link_share(context))
    end)
end

return M
