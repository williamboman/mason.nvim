local path = require "mason-core.path"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local log = require "mason-core.log"
local fs = require "mason-core.fs"

local M = {}

---@param pkg Package
---@param links InstallReceiptLinks
local function unlink_bin(pkg, links)
    for executable in pairs(links.bin) do
        local bin_path = path.bin_prefix(executable)
        fs.sync.unlink(bin_path)
    end
end

---@param pkg Package
---@param links InstallReceiptLinks
function M.unlink(pkg, links)
    log.fmt_debug("Unlinking %s", pkg)
    unlink_bin(pkg, links)
end

---@param to string
local function relative_path_from_bin(to)
    local _, match_end = to:find(path.install_prefix(), 1, true)
    assert(match_end, "Failed to produce relative path.")
    local relative_path = to:sub(match_end + 1)
    return ".." .. relative_path
end

---@async
---@param context InstallContext
local function link_bin(context)
    local links = context.bin_links
    local pkg = context.package
    for name, rel_path in pairs(links) do
        local target_abs_path = path.concat { pkg:get_install_path(), rel_path }
        local target_rel_path = relative_path_from_bin(target_abs_path)
        local bin_path = path.bin_prefix(name)

        assert(not fs.async.file_exists(bin_path), ("bin/%s is already linked."):format(name))
        assert(fs.async.file_exists(target_abs_path), ("Link target %q does not exist."):format(target_abs_path))

        log.fmt_debug("Linking bin %s to %s", name, target_rel_path)

        platform.when {
            unix = function()
                fs.async.symlink(target_rel_path, bin_path)
            end,
            win = function()
                -- We don't "symlink" on Windows because:
                -- 1) .LNK is not commonly found in PATHEXT
                -- 2) some executables can only run from their true installation location
                -- 3) many utilities only consider .COM, .EXE, .CMD, .BAT files as candidates by default when resolving executables (e.g. neovim's |exepath()| and |executable()|)
                fs.async.write_file(
                    ("%s.cmd"):format(bin_path),
                    _.dedent(([[
                        @ECHO off
                        GOTO start
                        :find_dp0
                        SET dp0=%%~dp0
                        EXIT /b
                        :start
                        SETLOCAL
                        CALL :find_dp0

                        endLocal & goto #_undefined_# 2>NUL || title %%COMSPEC%% & "%%dp0%%\%s" %%*
                ]]):format(target_rel_path))
                )
            end,
        }
        context.receipt:with_link("bin", name, rel_path)
    end
end

---@async
---@param context InstallContext
function M.link(context)
    log.fmt_debug("Linking %s", context.package)
    link_bin(context)
end

return M
