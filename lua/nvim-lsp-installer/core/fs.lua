local uv = require "nvim-lsp-installer.core.async.uv"
local log = require "nvim-lsp-installer.log"
local a = require "nvim-lsp-installer.core.async"
local Path = require "nvim-lsp-installer.path"
local settings = require "nvim-lsp-installer.settings"

local M = {}

---@async
---@param path string
function M.file_exists(path)
    local ok, fd = pcall(uv.fs_open, path, "r", 438)
    if not ok then
        return false
    end
    local fstat = uv.fs_fstat(fd)
    uv.fs_close(fd)
    return fstat.type == "file"
end

---@async
---@param path string
function M.dir_exists(path)
    local ok, fd = pcall(uv.fs_open, path, "r", 438)
    if not ok then
        return false
    end
    local fstat = uv.fs_fstat(fd)
    uv.fs_close(fd)
    return fstat.type == "directory"
end

---@async
---@param path string
function M.rmrf(path)
    assert(
        Path.is_subdirectory(settings.current.install_root_dir, path),
        (
            "Refusing to rmrf %q which is outside of the allowed boundary %q. Please report this error at https://github.com/williamboman/nvim-lsp-installer/issues/new"
        ):format(path, settings.current.install_root_dir)
    )
    log.debug("fs: rmrf", path)
    if vim.in_fast_event() then
        a.scheduler()
    end
    if vim.fn.delete(path, "rf") ~= 0 then
        log.debug "fs: rmrf failed"
        error(("rmrf: Could not remove directory %q."):format(path))
    end
end

---@async
---@param path string
function M.unlink(path)
    log.debug("fs: unlink", path)
    uv.fs_unlink(path)
end

---@async
---@param path string
function M.mkdir(path)
    log.debug("fs: mkdir", path)
    uv.fs_mkdir(path, 493) -- 493(10) == 755(8)
end

---@async
---@param path string
function M.mkdirp(path)
    log.debug("fs: mkdirp", path)
    if vim.in_fast_event() then
        a.scheduler()
    end
    if vim.fn.mkdir(path, "p") ~= 1 then
        log.debug "fs: mkdirp failed"
        error(("mkdirp: Could not create directory %q."):format(path))
    end
end

---@async
---@param path string
---@param new_path string
function M.rename(path, new_path)
    log.debug("fs: rename", path, new_path)
    uv.fs_rename(path, new_path)
end

---@async
---@param path string
---@param contents string
---@param flags string @Defaults to "w".
function M.write_file(path, contents, flags)
    log.fmt_debug("fs: write_file %s", path)
    local fd = assert(uv.fs_open(path, flags or "w", 438))
    uv.fs_write(fd, contents, -1)
    assert(uv.fs_close(fd))
end

---@async
---@param path string
---@param contents string
function M.append_file(path, contents)
    M.write_file(path, contents, "a")
end

return M
