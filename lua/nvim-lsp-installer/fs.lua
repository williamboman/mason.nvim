local uv = vim.loop
local M = {}

local function escape_quotes(str)
    return string.format("%q", str)
end

function M.mkdirp(path)
    if os.execute("mkdir -p " .. escape_quotes(path)) ~= 0 then
        error(("mkdirp: Could not create directory %s"):format(path))
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
    -- giggity
    if os.execute("rm -rf " .. escape_quotes(path)) ~= 0 then
        error(("Could not remove LSP server directory %s"):format(path))
    end
end

return M
