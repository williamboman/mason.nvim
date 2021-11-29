local pathm = require "nvim-lsp-installer.path"
local log = require "nvim-lsp-installer.log"
local settings = require "nvim-lsp-installer.settings"

local uv = vim.loop
local M = {}

local function assert_ownership(path)
    if not pathm.is_subdirectory(settings.current.install_root_dir, path) then
        log.fmt_error("assert_ownership() failed on path %s", path)
        error(
            ("Refusing to operate on path (%s) outside of the servers root dir (%s)."):format(
                path,
                settings.current.install_root_dir
            )
        )
    end
end

---@param path string @The full path to the file/dir to recursively delete. Will refuse to operate on paths outside of the install_root dir setting.
function M.rmrf(path)
    log.debug("fs: rmrf", path)
    assert_ownership(path)
    if vim.fn.delete(path, "rf") ~= 0 then
        log.debug "fs: rmrf failed"
        error(("rmrf: Could not remove directory %q."):format(path))
    end
end

---@param path string @The full path to the file/dir to rename. Will refuse to operate on paths outside of the install_root dir setting.
---@param new_path string @The full path to the new file/dir name. Will refuse to operate on paths outside of the install_root dir setting.
function M.rename(path, new_path)
    log.debug("fs: rename", path, new_path)
    assert_ownership(path)
    assert_ownership(new_path)
    assert(uv.fs_rename(path, new_path))
end

---@param path string @The full path to the directory to create. Will refuse to operate on paths outside of the install_root dir setting.
function M.mkdirp(path)
    log.debug("fs: mkdirp", path)
    assert_ownership(path)
    if vim.fn.mkdir(path, "p") ~= 1 then
        log.debug "fs: mkdirp failed"
        error(("mkdirp: Could not create directory %q."):format(path))
    end
end

---@param path string @The full path to the directory to create. Will refuse to operate on paths outside of the install_root dir setting.
function M.mkdir(path)
    log.debug("fs: mkdir", path)
    assert_ownership(path)
    assert(uv.fs_mkdir(path, 493)) -- 493(10) == 755(8)
end

---Recursively removes the path if it exists before creating a directory.
---@param path string @The full path to the directory to create. Will refuse to operate on paths outside of the install_root dir setting.
function M.rm_mkdirp(path)
    if M.dir_exists(path) then
        M.rmrf(path)
    end
    return M.mkdirp(path)
end

---@param path string @The full path to check if it 1) exists, and 2) is a directory.
---@return boolean
function M.dir_exists(path)
    local ok, stat = pcall(M.fstat, path)
    if not ok then
        return false
    end
    return stat.type == "directory"
end

---@param path string @The full path to check if it 1) exists, and 2) is a file.
---@return boolean
function M.file_exists(path)
    local ok, stat = pcall(M.fstat, path)
    if not ok then
        return false
    end
    return stat.type == "file"
end

---@param path string @The full path to the file to get the file status from.
---@return table @Returns a struct of type uv_fs_t.
function M.fstat(path)
    local fd = assert(uv.fs_open(path, "r", 438))
    local fstat = assert(uv.fs_fstat(fd))
    assert(uv.fs_close(fd))
    return fstat
end

---@param path string @The full path to the file to write.
---@param contents string @The contents to write.
function M.write_file(path, contents)
    log.fmt_debug("fs: write_file %s", path)
    assert_ownership(path)
    local fd = assert(uv.fs_open(path, "w", 438))
    uv.fs_write(fd, contents, -1)
    assert(uv.fs_close(fd))
end

function M.append_file(path, contents)
    log.fmt_debug("fs: append_file %s", path)
    assert_ownership(path)
    local fd = assert(uv.fs_open(path, "a", 438))
    uv.fs_write(fd, contents, -1)
    assert(uv.fs_close(fd))
end

---@alias ReaddirEntry {name: string, type: string}

---@param path string @The full path to the directory to read.
---@return ReaddirEntry[]
function M.readdir(path)
    local dir = assert(uv.fs_opendir(path, nil, 25))
    local all_entries = {}
    local exhausted = false

    repeat
        local entries = uv.fs_readdir(dir)
        if entries and #entries > 0 then
            for i = 1, #entries do
                all_entries[#all_entries + 1] = entries[i]
            end
        else
            exhausted = true
        end
    until exhausted

    assert(uv.fs_closedir(dir))

    return all_entries
end

return M
