local Optional = require "mason-core.optional"
local _ = require "mason-core.functional"
local fs = require "mason-core.fs"
local log = require "mason-core.log"
local path = require "mason-core.path"
local platform = require "mason-core.platform"
local receipt = require "mason-core.receipt"
local spawn = require "mason-core.spawn"

---@class ContextualSpawn
---@field strict_mode boolean Whether spawn failures should raise an exception rather then return a Result.
---@field cwd CwdManager
---@field handle InstallHandle
---@field [string] async fun(opts: SpawnArgs): Result
local ContextualSpawn = {}

---@param cwd CwdManager
---@param handle InstallHandle
---@param strict_mode boolean
function ContextualSpawn.new(cwd, handle, strict_mode)
    return setmetatable({ cwd = cwd, handle = handle, strict_mode = strict_mode }, ContextualSpawn)
end

---@param cmd string
function ContextualSpawn:__index(cmd)
    ---@param args JobSpawnOpts
    return function(args)
        args.cwd = args.cwd or self.cwd:get()
        args.stdio_sink = args.stdio_sink or self.handle.stdio.sink
        local on_spawn = args.on_spawn
        local captured_handle
        args.on_spawn = function(handle, stdio, pid, ...)
            captured_handle = handle
            self.handle:register_spawn_handle(handle, pid, cmd, spawn._flatten_cmd_args(args))
            if on_spawn then
                on_spawn(handle, stdio, pid, ...)
            end
        end
        local function pop_spawn_stack()
            if captured_handle then
                self.handle:deregister_spawn_handle(captured_handle)
            end
        end
        local result = spawn[cmd](args):on_success(pop_spawn_stack):on_failure(pop_spawn_stack)
        if self.strict_mode then
            return result:get_or_throw()
        else
            return result
        end
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
---@param rel_path string The relative path from the current working directory to the file to append.
---@param contents string
function ContextualFs:append_file(rel_path, contents)
    return fs.async.append_file(path.concat { self.cwd:get(), rel_path }, contents)
end

---@async
---@param rel_path string The relative path from the current working directory to the file to write.
---@param contents string
function ContextualFs:write_file(rel_path, contents)
    return fs.async.write_file(path.concat { self.cwd:get(), rel_path }, contents)
end

---@async
---@param rel_path string The relative path from the current working directory to the file to read.
function ContextualFs:read_file(rel_path)
    return fs.async.read_file(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string The relative path from the current working directory.
function ContextualFs:file_exists(rel_path)
    return fs.async.file_exists(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string The relative path from the current working directory.
function ContextualFs:dir_exists(rel_path)
    return fs.async.dir_exists(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string The relative path from the current working directory.
function ContextualFs:rmrf(rel_path)
    return fs.async.rmrf(path.concat { self.cwd:get(), rel_path })
end

---@async
---@param rel_path string The relative path from the current working directory.
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
---@param dir_path string
function ContextualFs:mkdir(dir_path)
    return fs.async.mkdir(path.concat { self.cwd:get(), dir_path })
end

---@async
---@param dir_path string
function ContextualFs:mkdirp(dir_path)
    return fs.async.mkdirp(path.concat { self.cwd:get(), dir_path })
end

---@async
---@param file_path string
function ContextualFs:chmod_exec(file_path)
    local bit = require "bit"
    -- see chmod(2)
    local USR_EXEC = 0x40
    local GRP_EXEC = 0x8
    local ALL_EXEC = 0x1
    local EXEC = bit.bor(USR_EXEC, GRP_EXEC, ALL_EXEC)
    local fstat = self:fstat(file_path)
    if bit.band(fstat.mode, EXEC) ~= EXEC then
        local plus_exec = bit.bor(fstat.mode, EXEC)
        log.fmt_debug("Setting exec flags on file %s %o -> %o", file_path, fstat.mode, plus_exec)
        self:chmod(file_path, plus_exec) -- chmod +x
    end
end

---@async
---@param file_path string
---@param mode integer
function ContextualFs:chmod(file_path, mode)
    return fs.async.chmod(path.concat { self.cwd:get(), file_path }, mode)
end

---@async
---@param file_path string
function ContextualFs:fstat(file_path)
    return fs.async.fstat(path.concat { self.cwd:get(), file_path })
end

---@class CwdManager
---@field private install_prefix string Defines the upper boundary for which paths are allowed as cwd.
---@field private cwd string
local CwdManager = {}
CwdManager.__index = CwdManager

function CwdManager.new(install_prefix)
    assert(type(install_prefix) == "string", "install_prefix not provided")
    return setmetatable({
        install_prefix = install_prefix,
        cwd = nil,
    }, CwdManager)
end

function CwdManager:get()
    assert(self.cwd ~= nil, "Tried to access cwd before it was set.")
    return self.cwd
end

---@param new_cwd string
function CwdManager:set(new_cwd)
    assert(type(new_cwd) == "string", "new_cwd is not a string")
    assert(
        path.is_subdirectory(self.install_prefix, new_cwd),
        ("%q is not a subdirectory of %q"):format(new_cwd, self.install_prefix)
    )
    self.cwd = new_cwd
end

---@class InstallContext
---@field public receipt InstallReceiptBuilder
---@field public requested_version Optional
---@field public fs ContextualFs
---@field public spawn ContextualSpawn
---@field public handle InstallHandle
---@field public package Package
---@field public cwd CwdManager
---@field public opts PackageInstallOpts
---@field public stdio_sink StdioSink
---@field links { bin: table<string, string>, share: table<string, string>, opt: table<string, string> }
local InstallContext = {}
InstallContext.__index = InstallContext

---@param handle InstallHandle
---@param opts PackageInstallOpts
function InstallContext.new(handle, opts)
    local cwd_manager = CwdManager.new(path.install_prefix())
    return setmetatable({
        cwd = cwd_manager,
        spawn = ContextualSpawn.new(cwd_manager, handle, not handle.package:is_registry_spec()),
        handle = handle,
        package = handle.package, -- for convenience
        fs = ContextualFs.new(cwd_manager),
        receipt = receipt.InstallReceiptBuilder.new(),
        requested_version = Optional.of_nilable(opts.version),
        stdio_sink = handle.stdio.sink,
        links = {
            bin = {},
            share = {},
            opt = {},
        },
        opts = opts,
    }, InstallContext)
end

---@async
function InstallContext:promote_cwd()
    local cwd = self.cwd:get()
    local install_path = self.package:get_install_path()
    if install_path == cwd then
        log.fmt_debug("cwd %s is already promoted (at %s)", cwd, install_path)
        return
    end
    log.fmt_debug("Promoting cwd %s to %s", cwd, install_path)
    -- 1. Unlink any existing installation
    self.handle.package:unlink()
    -- 2. Prepare for renaming cwd to destination
    if platform.is.unix then
        -- Some Unix systems will raise an error when renaming a directory to a destination that does not already exist.
        fs.async.mkdir(install_path)
    end
    -- 3. Move the cwd to the final installation directory
    fs.async.rename(cwd, install_path)
    -- 4. Update cwd
    self.cwd:set(install_path)
end

---@param rel_path string The relative path from the current working directory to change cwd to. Will only restore to the initial cwd after execution of fn (if provided).
---@param fn async (fun(): any)? The function to run in the context of the given path.
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

---@param new_executable_rel_path string Relative path to the executable file to create.
---@param script_rel_path string Relative path to the Node.js script.
function InstallContext:write_node_exec_wrapper(new_executable_rel_path, script_rel_path)
    if not self.fs:file_exists(script_rel_path) then
        error(("Cannot write Node exec wrapper for path %q as it doesn't exist."):format(script_rel_path), 0)
    end
    return self:write_shell_exec_wrapper(
        new_executable_rel_path,
        ("node %q"):format(path.concat {
            self.package:get_install_path(),
            script_rel_path,
        })
    )
end

---@param new_executable_rel_path string Relative path to the executable file to create.
---@param script_rel_path string Relative path to the Node.js script.
function InstallContext:write_ruby_exec_wrapper(new_executable_rel_path, script_rel_path)
    if not self.fs:file_exists(script_rel_path) then
        error(("Cannot write Ruby exec wrapper for path %q as it doesn't exist."):format(script_rel_path), 0)
    end
    return self:write_shell_exec_wrapper(
        new_executable_rel_path,
        ("ruby %q"):format(path.concat {
            self.package:get_install_path(),
            script_rel_path,
        })
    )
end

---@param new_executable_rel_path string Relative path to the executable file to create.
---@param script_rel_path string Relative path to the PHP script.
function InstallContext:write_php_exec_wrapper(new_executable_rel_path, script_rel_path)
    if not self.fs:file_exists(script_rel_path) then
        error(("Cannot write PHP exec wrapper for path %q as it doesn't exist."):format(script_rel_path), 0)
    end
    return self:write_shell_exec_wrapper(
        new_executable_rel_path,
        ("php %q"):format(path.concat {
            self.package:get_install_path(),
            script_rel_path,
        })
    )
end

---@param new_executable_rel_path string Relative path to the executable file to create.
---@param module string The python module to call.
function InstallContext:write_pyvenv_exec_wrapper(new_executable_rel_path, module)
    local pip3 = require "mason-core.managers.pip3"
    local module_exists, module_err = pcall(function()
        local result =
            self.spawn.python { "-c", ("import %s"):format(module), with_paths = { pip3.venv_path(self.cwd:get()) } }
        if not self.spawn.strict_mode then
            result:get_or_throw()
        end
    end)
    if not module_exists then
        log.fmt_error("Failed to find module %q for package %q. %s", module, self.package, module_err)
        error(("Cannot write Python exec wrapper for module %q as it doesn't exist."):format(module), 0)
    end
    return self:write_shell_exec_wrapper(
        new_executable_rel_path,
        ("%q -m %s"):format(
            path.concat {
                pip3.venv_path(self.package:get_install_path()),
                "python",
            },
            module
        )
    )
end

---@param new_executable_rel_path string Relative path to the executable file to create.
---@param target_executable_rel_path string
function InstallContext:write_exec_wrapper(new_executable_rel_path, target_executable_rel_path)
    if not self.fs:file_exists(target_executable_rel_path) then
        error(("Cannot write exec wrapper for path %q as it doesn't exist."):format(target_executable_rel_path), 0)
    end
    if platform.is.unix then
        self.fs:chmod_exec(target_executable_rel_path)
    end
    return self:write_shell_exec_wrapper(
        new_executable_rel_path,
        ("%q"):format(path.concat {
            self.package:get_install_path(),
            target_executable_rel_path,
        })
    )
end

local BASH_TEMPLATE = _.dedent [[
#!/usr/bin/env bash
%s
exec %s "$@"
]]

local BATCH_TEMPLATE = _.dedent [[
@ECHO off
%s
%s %%*
]]

---@param new_executable_rel_path string Relative path to the executable file to create.
---@param command string The shell command to run.
---@param env table<string, string>?
---@return string # The created executable filename.
function InstallContext:write_shell_exec_wrapper(new_executable_rel_path, command, env)
    if self.fs:file_exists(new_executable_rel_path) or self.fs:dir_exists(new_executable_rel_path) then
        error(("Cannot write exec wrapper to %q because the file already exists."):format(new_executable_rel_path), 0)
    end
    return platform.when {
        unix = function()
            local std = require "mason-core.managers.std"
            local formatted_envs = _.map(function(pair)
                local var, value = pair[1], pair[2]
                return ("export %s=%q"):format(var, value)
            end, _.to_pairs(env or {}))

            self.fs:write_file(new_executable_rel_path, BASH_TEMPLATE:format(_.join("\n", formatted_envs), command))
            std.chmod("+x", { new_executable_rel_path })
            return new_executable_rel_path
        end,
        win = function()
            local executable_file = ("%s.cmd"):format(new_executable_rel_path)
            local formatted_envs = _.map(function(pair)
                local var, value = pair[1], pair[2]
                return ("SET %s=%s"):format(var, value)
            end, _.to_pairs(env or {}))

            self.fs:write_file(executable_file, BATCH_TEMPLATE:format(_.join("\n", formatted_envs), command))
            return executable_file
        end,
    }
end

---@param executable string
---@param rel_path string
function InstallContext:link_bin(executable, rel_path)
    self.links.bin[executable] = rel_path
    return self
end

return InstallContext
