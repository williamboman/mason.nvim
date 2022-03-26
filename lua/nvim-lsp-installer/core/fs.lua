local uv = require "nvim-lsp-installer.core.async.uv"
local log = require "nvim-lsp-installer.log"
local a = require "nvim-lsp-installer.core.async"

local M = {}

---@async
---@param path string
---@param contents string
function M.append_file(path, contents)
    local fd = uv.fs_open(path, "a", 438)
    uv.fs_write(fd, contents, -1)
    uv.fs_close(fd)
end

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
function M.mkdir(path)
    log.debug("fs: mkdir", path)
    uv.fs_mkdir(path, 493) -- 493(10) == 755(8)
end

---@async
---@param path string
---@param new_path string
function M.rename(path, new_path)
    log.debug("fs: rename", path, new_path)
    uv.fs_rename(path, new_path)
end

return M
