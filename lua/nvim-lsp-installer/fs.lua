local uv = vim.loop
local M = {}

function M.mkdirp(path)
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
    return assert(uv.fs_fstat(fd))
end

function M.rmrf(path)
    if vim.fn.delete(path, "rf") ~= 0 then
        error(("rmrf: Could not remove directory %q."):format(path))
    end
end

return M
