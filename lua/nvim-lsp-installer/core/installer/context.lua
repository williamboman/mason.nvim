local spawn = require "nvim-lsp-installer.core.spawn"
local log = require "nvim-lsp-installer.log"
local fs = require "nvim-lsp-installer.core.fs"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"
local receipt = require "nvim-lsp-installer.core.receipt"

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
    return fs.append_file(path.concat { self.cwd:get(), rel_path }, contents)
end

---@async
---@param rel_path string @The relative path from the current working directory to the file to write.
---@param contents string
function ContextualFs:write_file(rel_path, contents)
    return fs.write_file(path.concat { self.cwd:get(), rel_path }, contents)
end

---@async
---@param rel_path string @The relative path from the current working directory.
function ContextualFs:file_exists(rel_path)
    return fs.file_exists(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string @The relative path from the current working directory.
function ContextualFs:dir_exists(rel_path)
    return fs.dir_exists(path.concat { self.cwd:get(), rel_path })
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
    return assert(self.cwd, "Tried to access cwd before it was set.")
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
    if fs.dir_exists(self.destination_dir) then
        fs.rmrf(self.destination_dir)
    end
    -- 2. Prepare for renaming cwd to destination
    if platform.is_unix then
        -- Some Unix systems will raise an error when renaming a directory to a destination that does not already exist.
        fs.mkdir(self.destination_dir)
    end
    -- 3. Move the cwd to the final installation directory
    fs.rename(cwd, self.destination_dir)
    -- 4. Update cwd
    self.cwd:set(self.destination_dir)
end

return InstallContext
