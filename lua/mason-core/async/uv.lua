local a = require "mason-core.async"

---@type table<UvMethod, async fun(...)>
local M = setmetatable({}, {
    __index = function(cache, method)
        cache[method] = a.promisify(vim.loop[method], true)
        return cache[method]
    end,
})

return M

---@alias UvMethod
---| '"write"'
---| '"shutdown"'
---| '"close"'
---| '"fs_close"'
---| '"fs_open"'
---| '"fs_read"'
---| '"fs_unlink"'
---| '"fs_write"'
---| '"fs_mkdir"'
---| '"fs_mkdtemp"'
---| '"fs_mkstemp"'
---| '"fs_rmdir"'
---| '"fs_scandir"'
---| '"fs_stat"'
---| '"fs_fstat"'
---| '"fs_lstat"'
---| '"fs_rename"'
---| '"fs_fsync"'
---| '"fs_fdatasync"'
---| '"fs_ftruncate"'
---| '"fs_sendfile"'
---| '"fs_access"'
---| '"fs_chmod"'
---| '"fs_fchmod"'
---| '"fs_utime"'
---| '"fs_futime"'
---| '"fs_lutime"'
---| '"fs_link"'
---| '"fs_symlink"'
---| '"fs_readlink"'
---| '"fs_realpath"'
---| '"fs_chown"'
---| '"fs_fchown"'
---| '"fs_lchown"'
---| '"fs_copyfile"'
---| '"fs_opendir"'
---| '"fs_readdir"'
---| '"fs_closedir"'
---| '"fs_statfs"'
