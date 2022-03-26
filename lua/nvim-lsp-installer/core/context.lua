local spawn = require "nvim-lsp-installer.core.spawn"
local log = require "nvim-lsp-installer.log"
local Optional = require "nvim-lsp-installer.core.optional"
local fs = require "nvim-lsp-installer.core.fs"
local settings = require "nvim-lsp-installer.settings"
local Result = require "nvim-lsp-installer.core.result"
local path = require "nvim-lsp-installer.path"
local platform = require "nvim-lsp-installer.platform"

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
local CwdManager = {}
CwdManager.__index = CwdManager
function CwdManager.new(cwd)
    return setmetatable({ cwd = cwd }, CwdManager)
end
function CwdManager:get()
    return self.cwd
end
function CwdManager:set(new_cwd)
    self.cwd = new_cwd
end

---@class InstallContext
---@field public receipt InstallReceiptBuilder
---@field public requested_version Optional
---@field public fs ContextualFs
---@field public spawn JobSpawn
---@field private cwd_manager CwdManager
---@field private destination_dir string
local InstallContext = {}
InstallContext.__index = InstallContext

function InstallContext.new(opts)
    local cwd_manager = CwdManager.new(opts.cwd)
    return setmetatable({
        cwd_manager = cwd_manager,
        spawn = ContextualSpawn.new(cwd_manager, opts.stdio_sink),
        fs = ContextualFs.new(cwd_manager),
        receipt = opts.receipt,
        requested_version = opts.requested_version,
        destination_dir = opts.destination_dir,
    }, InstallContext)
end

---@deprecated
---@param ctx ServerInstallContext
---@param destination_dir string
function InstallContext.from_server_context(ctx, destination_dir)
    return InstallContext.new {
        cwd = ctx.install_dir,
        receipt = ctx.receipt,
        stdio_sink = ctx.stdio_sink,
        requested_version = Optional.of_nilable(ctx.requested_server_version),
        destination_dir = destination_dir,
    }
end

function InstallContext:cwd()
    return self.cwd_manager:get()
end

---@param new_cwd string @The new cwd (absolute path).
function InstallContext:set_cwd(new_cwd)
    self
        :ensure_path_ownership(new_cwd)
        :map(function(p)
            self.cwd_manager:set(p)
            return p
        end)
        :get_or_throw()
end

---@param abs_path string
function InstallContext:ensure_path_ownership(abs_path)
    if path.is_subdirectory(self:cwd_manager(), abs_path) or self.destination_dir == abs_path then
        return Result.success(abs_path)
    else
        return Result.failure(
            ("Path %q is outside of current path ownership (%q)."):format(abs_path, settings.current.install_root_dir)
        )
    end
end

---@async
function InstallContext:promote_cwd()
    local cwd = self:cwd()
    if self.destination_dir == cwd then
        log.fmt_debug("cwd %s is already promoted (at %s)", cwd, self.destination_dir)
        return Result.success "Current working dir is already in destination."
    end
    log.fmt_debug("Promoting cwd %s to %s", cwd, self.destination_dir)
    return Result.run_catching(function()
        -- 1. Remove destination dir, if it exists
        if fs.dir_exists(self.destination_dir) then
            fs.rmrf(self.destination_dir)
        end
        return self.destination_dir
    end)
        :map_catching(function(destination_dir)
            -- 2. Prepare for renaming cwd to destination
            if platform.is_unix then
                -- Some Unix systems will raise an error when renaming a directory to a destination that does not already exist.
                fs.mkdir(destination_dir)
            end
            return destination_dir
        end)
        :map_catching(function(destination_dir)
            -- 3. Move the cwd to the final installation directory
            fs.rename(cwd, destination_dir)
            return destination_dir
        end)
        :map_catching(function(destination_dir)
            -- 4. Update cwd
            self:set_cwd(destination_dir)
        end)
end

return InstallContext
