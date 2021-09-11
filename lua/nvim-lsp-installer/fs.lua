local pathm = require("nvim-lsp-installer.path")

local uv = vim.loop
local M = {}

local function assert_ownership(path)
    if not pathm.is_subdirectory(pathm.SERVERS_ROOT_DIR, path) then
        error(("Refusing to operate on path outside of the servers root dir (%s)."):format(pathm.SERVERS_ROOT_DIR))
    end
end

function M.rmrf(path)
    assert_ownership(path)
    if vim.fn.delete(path, "rf") ~= 0 then
        error(("rmrf: Could not remove directory %q."):format(path))
    end
end

function M.mkdirp(path)
    assert_ownership(path)
    if vim.fn.mkdir(path, "p") ~= 1 then
        error(("mkdirp: Could not create directory %q."):format(path))
    end
end

function M.dir_exists(path)
    local ok, stat = pcall(M.fstat, path)
    if not ok then
        return false
    end
    return stat.type == "directory"
end

function M.file_exists(path)
    local ok, stat = pcall(M.fstat, path)
    if not ok then
        return false
    end
    return stat.type == "file"
end

function M.fstat(path)
    local fd = assert(uv.fs_open(path, "r", 438))
    local fstat = assert(uv.fs_fstat(fd))
    assert(uv.fs_close(fd))
    return fstat
end

return M
