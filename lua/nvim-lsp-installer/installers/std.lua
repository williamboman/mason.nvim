local path = require "nvim-lsp-installer.path"
local fs = require "nvim-lsp-installer.fs"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"

local M = {}

---@param url string @The url to download.
---@param out_file string @The relative path to where to write the contents of the url.
function M.download_file(url, out_file)
    return installers.when {
        ---@type ServerInstallerFunction
        unix = function(_, callback, context)
            context.stdio_sink.stdout(("Downloading file %q...\n"):format(url))
            process.attempt {
                jobs = {
                    process.lazy_spawn("wget", {
                        args = { "-nv", "-O", out_file, url },
                        cwd = context.install_dir,
                        stdio_sink = context.stdio_sink,
                    }),
                    process.lazy_spawn("curl", {
                        args = { "-fsSL", "-o", out_file, url },
                        cwd = context.install_dir,
                        stdio_sink = context.stdio_sink,
                    }),
                },
                on_finish = callback,
            }
        end,
        win = shell.powershell(("iwr -UseBasicParsing -Uri %q -OutFile %q"):format(url, out_file)),
    }
end

---@param file string @The relative path to the file to unzip.
---@param dest string|nil @The destination of the unzip.
function M.unzip(file, dest)
    return installers.pipe {
        installers.when {
            ---@type ServerInstallerFunction
            unix = function(_, callback, context)
                process.spawn("unzip", {
                    args = { "-d", dest, file },
                    cwd = context.install_dir,
                    stdio_sink = context.stdio_sink,
                }, callback)
            end,
            win = shell.powershell(
                ("Microsoft.PowerShell.Archive\\Expand-Archive -Path %q -DestinationPath %q"):format(file, dest)
            ),
        },
        installers.always_succeed(M.rmrf(file)),
    }
end

---@see unzip().
---@param url string @The url of the .zip file.
---@param dest string|nil @The url of the .zip file. Defaults to ".".
function M.unzip_remote(url, dest)
    return installers.pipe {
        M.download_file(url, "archive.zip"),
        M.unzip("archive.zip", dest or "."),
    }
end

---@param file string @The relative path to the tar file to extract.
function M.untar(file)
    return installers.pipe {
        ---@type ServerInstallerFunction
        function(_, callback, context)
            process.spawn("tar", {
                args = { "-xvf", file },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
        installers.always_succeed(M.rmrf(file)),
    }
end

---@param file string
local function win_extract(file)
    return installers.pipe {
        ---@type ServerInstallerFunction
        function(_, callback, context)
            -- The trademarked "throw shit until it sticks" technique
            local sevenzip = process.lazy_spawn("7z", {
                args = { "x", "-y", "-r", file },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            })
            local peazip = process.lazy_spawn("peazip", {
                args = { "-ext2here", path.concat { context.install_dir, file } }, -- peazip require absolute paths, or else!
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            })
            local winzip = process.lazy_spawn("wzunzip", {
                args = { file },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            })
            process.attempt {
                jobs = { sevenzip, peazip, winzip },
                on_finish = callback,
            }
        end,
        installers.always_succeed(M.rmrf(file)),
    }
end

---@param file string
local function win_untarxz(file)
    return installers.pipe {
        win_extract(file),
        M.untar(file:gsub(".xz$", "")),
    }
end

---@param file string
local function win_arc_unarchive(file)
    return installers.pipe {
        ---@type ServerInstallerFunction
        function(_, callback, context)
            context.stdio_sink.stdout "Attempting to unarchive using arc."
            process.spawn("arc", {
                args = { "unarchive", file },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
        installers.always_succeed(M.rmrf(file)),
    }
end

---@param url string @The url to the .tar.xz file to extract.
function M.untarxz_remote(url)
    return installers.pipe {
        M.download_file(url, "archive.tar.xz"),
        installers.when {
            unix = M.untar "archive.tar.xz",
            win = installers.first_successful {
                win_untarxz "archive.tar.xz",
                win_arc_unarchive "archive.tar.xz",
            },
        },
    }
end

---@param url string @The url to the .tar.gz file to extract.
function M.untargz_remote(url)
    return installers.pipe {
        M.download_file(url, "archive.tar.gz"),
        M.untar "archive.tar.gz",
    }
end

---@param file string @The relative path to the file to gunzip.
function M.gunzip(file)
    return installers.when {
        ---@type ServerInstallerFunction
        unix = function(_, callback, context)
            process.spawn("gzip", {
                args = { "-d", file },
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
        win = win_extract(file),
    }
end

---@see gunzip()
---@param url string @The url to the .gz file to extract.
---@param out_file string|nil @The name of the extracted .gz file.
function M.gunzip_remote(url, out_file)
    local archive = ("%s.gz"):format(out_file or "archive")
    return installers.pipe {
        M.download_file(url, archive),
        M.gunzip(archive),
        installers.always_succeed(M.rmrf(archive)),
    }
end

---Recursively deletes the provided path. Will fail on paths that are not inside the configured install_root_dir.
---@param rel_path string @The relative path to the file/directory to remove.
function M.rmrf(rel_path)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        local abs_path = path.concat { context.install_dir, rel_path }
        context.stdio_sink.stdout(("Deleting %q\n"):format(abs_path))
        vim.schedule(function()
            local ok = pcall(fs.rmrf, abs_path)
            if ok then
                callback(true)
            else
                context.stdio_sink.stderr(("Failed to delete %q.\n"):format(abs_path))
                callback(false)
            end
        end)
    end
end

---@param rel_path string @The relative path to the file to write.
---@param contents string @The file contents.
function M.write_file(rel_path, contents)
    ---@type ServerInstallerFunction
    return function(_, callback, ctx)
        local file = path.concat { ctx.install_dir, rel_path }
        ctx.stdio_sink.stdout(("Writing file %q\n"):format(file))
        fs.write_file(file, contents)
        callback(true)
    end
end

---@param script_rel_path string @The relative path to the script file to write.
---@param abs_target_executable_path string @The absolute path to the executable that is being aliased.
function M.executable_alias(script_rel_path, abs_target_executable_path)
    local windows_script = "@call %q %%"
    local unix_script = [[#!/usr/bin/env sh
exec %q
]]
    return installers.when {
        unix = M.write_file(script_rel_path, unix_script:format(abs_target_executable_path)),
        win = M.write_file(script_rel_path, windows_script:format(abs_target_executable_path)),
    }
end

---Shallow git clone.
---@param repo_url string
function M.git_clone(repo_url)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        local c = process.chain {
            cwd = context.install_dir,
            stdio_sink = context.stdio_sink,
        }

        c.run("git", { "clone", "--depth", "1", repo_url, "." })

        if context.requested_server_version then
            c.run("git", { "fetch", "--depth", "1", "origin", context.requested_server_version })
            c.run("git", { "checkout", "FETCH_HEAD" })
        end

        c.spawn(callback)
    end
end

function M.git_submodule_update()
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        process.spawn("git", {
            args = { "submodule", "update", "--init", "--recursive" },
            cwd = context.install_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
end

---@param opts {args: string[]}
function M.gradlew(opts)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        process.spawn(path.concat { context.install_dir, platform.is_win and "gradlew.bat" or "gradlew" }, {
            args = opts.args,
            cwd = context.install_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
end

---Creates an installer that ensures that the provided executables are available in the current runtime.
---@param executables string[][] @A list of (executable, error_msg) tuples.
---@return ServerInstallerFunction
function M.ensure_executables(executables)
    return vim.schedule_wrap(
        ---@type ServerInstallerFunction
        function(_, callback, context)
            local has_error = false
            for i = 1, #executables do
                local entry = executables[i]
                local executable = entry[1]
                local error_msg = entry[2]
                if vim.fn.executable(executable) ~= 1 then
                    has_error = true
                    context.stdio_sink.stderr(error_msg .. "\n")
                end
            end
            callback(not has_error)
        end
    )
end

---@path old_path string @The relative path to the file/dir to rename.
---@path new_path string @The relative path to what to rename the file/dir to.
function M.rename(old_path, new_path)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        local ok = pcall(
            fs.rename,
            path.concat { context.install_dir, old_path },
            path.concat { context.install_dir, new_path }
        )
        if not ok then
            context.stdio_sink.stderr(("Failed to rename %q to %q.\n"):format(old_path, new_path))
        end
        callback(ok)
    end
end

---@param flags string @The chmod flag to apply.
---@param files string[] @A list of relative paths to apply the chmod on.
function M.chmod(flags, files)
    return installers.on {
        ---@type ServerInstallerFunction
        unix = function(_, callback, context)
            process.spawn("chmod", {
                args = vim.list_extend({ flags }, files),
                cwd = context.install_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
    }
end

return M
