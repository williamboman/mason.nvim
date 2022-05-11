local spawn = require "nvim-lsp-installer.core.spawn"
local log = require "nvim-lsp-installer.log"
local fs = require "nvim-lsp-installer.core.fs"
local path = require "nvim-lsp-installer.core.path"
local platform = require "nvim-lsp-installer.core.platform"
local receipt = require "nvim-lsp-installer.core.receipt"
local installer = require "nvim-lsp-installer.core.installer"
local a = require "nvim-lsp-installer.core.async"

---@class ContextualSpawn
---@field cwd CwdManager
---@field stdio_sink StdioSink
local ContextualSpawn = {}

---@param cwd CwdManager
---@param stdio_sink StdioSink
function ContextualSpawn.new(cwd, stdio_sink)
    return setmetatable({ cwd = cwd, stdio_sink = stdio_sink }, ContextualSpawn)
end
function ContextualSpawn.__index(self, cmd)
    return function(args)
        args.cwd = args.cwd or self.cwd:get()
        args.stdio_sink = args.stdio_sink or self.stdio_sink
        -- We get_or_throw() here for convenience reasons.
        -- Almost every time spawn is called via context we want the command to succeed.
        return spawn[cmd](args):get_or_throw()
    end
end

---@class ContextualFs
---@field private cwd CwdManager
local ContextualFs = {}
ContextualFs.__index = ContextualFs

---@param cwd CwdManager
function ContextualFs.new(cwd)
    return setmetatable({ cwd = cwd }, ContextualFs)
end

---@async
---@param rel_path string @The relative path from the current working directory to the file to append.
---@param contents string
function ContextualFs:append_file(rel_path, contents)
    return fs.async.append_file(path.concat { self.cwd:get(), rel_path }, contents)
end

---@async
---@param rel_path string @The relative path from the current working directory to the file to write.
---@param contents string
function ContextualFs:write_file(rel_path, contents)
    return fs.async.write_file(path.concat { self.cwd:get(), rel_path }, contents)
end

---@async
---@param rel_path string @The relative path from the current working directory.
function ContextualFs:file_exists(rel_path)
    return fs.async.file_exists(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string @The relative path from the current working directory.
function ContextualFs:dir_exists(rel_path)
    return fs.async.dir_exists(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string @The relative path from the current working directory.
function ContextualFs:rmrf(rel_path)
    return fs.async.rmrf(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string @The relative path from the current working directory.
function ContextualFs:unlink(rel_path)
    return fs.async.unlink(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param old_path string
---@param new_path string
function ContextualFs:rename(old_path, new_path)
    return fs.async.rename(path.concat { self.cwd:get(), old_path }, path.concat { self.cwd:get(), new_path })
end

---@async
---@param dirpath string
function ContextualFs:mkdir(dirpath)
    return fs.async.mkdir(path.concat { self.cwd:get(), dirpath })
end

---@class CwdManager
---@field private boundary_path string @Defines the upper boundary for which paths are allowed as cwd.
---@field private cwd string
local CwdManager = {}
CwdManager.__index = CwdManager

function CwdManager.new(boundary_path, cwd)
    assert(type(boundary_path) == "string")
    return setmetatable({
        boundary_path = boundary_path,
        cwd = cwd,
    }, CwdManager)
end

function CwdManager:get()
    assert(self.cwd ~= nil, "Tried to access cwd before it was set.")
    return self.cwd
end

---@param new_cwd string
function CwdManager:set(new_cwd)
    assert(type(new_cwd) == "string")
    assert(
        path.is_subdirectory(self.boundary_path, new_cwd),
        ("%q is not a subdirectory of %q"):format(new_cwd, self.boundary_path)
    )
    self.cwd = new_cwd
end

---@class InstallContext
---@field public name string
---@field public receipt InstallReceiptBuilder
---@field public requested_version Optional
---@field public fs ContextualFs
---@field public spawn JobSpawn
---@field public cwd CwdManager
---@field public destination_dir string
---@field public stdio_sink StdioSink
---@field public boundary_path string
local InstallContext = {}
InstallContext.__index = InstallContext

function InstallContext.new(opts)
    local cwd_manager = CwdManager.new(opts.boundary_path)
    return setmetatable({
        name = opts.name,
        cwd = cwd_manager,
        spawn = ContextualSpawn.new(cwd_manager, opts.stdio_sink),
        fs = ContextualFs.new(cwd_manager),
        receipt = receipt.InstallReceiptBuilder.new(),
        boundary_path = opts.boundary_path,
        destination_dir = opts.destination_dir,
        requested_version = opts.requested_version,
        stdio_sink = opts.stdio_sink,
    }, InstallContext)
end

---@async
function InstallContext:promote_cwd()
    local cwd = self.cwd:get()
    if self.destination_dir == cwd then
        log.fmt_debug("cwd %s is already promoted (at %s)", cwd, self.destination_dir)
        return
    end
    log.fmt_debug("Promoting cwd %s to %s", cwd, self.destination_dir)
    -- 1. Remove destination dir, if it exists
    if fs.async.dir_exists(self.destination_dir) then
        fs.async.rmrf(self.destination_dir)
    end
    -- 2. Prepare for renaming cwd to destination
    if platform.is_unix then
        -- Some Unix systems will raise an error when renaming a directory to a destination that does not already exist.
        fs.async.mkdir(self.destination_dir)
    end
    -- 3. Move the cwd to the final installation directory
    fs.async.rename(cwd, self.destination_dir)
    -- 4. Update cwd
    self.cwd:set(self.destination_dir)
end

---Runs the provided async functions concurrently and returns their result, once all are resolved.
---This is really just a wrapper around a.wait_all() that makes sure to patch the coroutine context before creating the
---new async execution contexts.
---@async
---@param suspend_fns async fun(ctx: InstallContext)[]
function InstallContext:run_concurrently(suspend_fns)
    return a.wait_all(vim.tbl_map(function(suspend_fn)
        return function()
            return installer.run_installer(self, suspend_fn)
        end
    end, suspend_fns))
end

---@param rel_path string @The relative path from the current working directory to change cwd to. Will only restore to the initial cwd after execution of fn (if provided).
---@param fn async fun() @(optional) The function to run in the context of the given path.
function InstallContext:chdir(rel_path, fn)
    local old_cwd = self.cwd:get()
    self.cwd:set(path.concat { old_cwd, rel_path })
    if fn then
        local ok, result = pcall(fn)
        self.cwd:set(old_cwd)
        if not ok then
            error(result, 0)
        end
        return result
    end
end

return InstallContext
