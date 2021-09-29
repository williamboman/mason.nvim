local path = require "nvim-lsp-installer.path"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"
local installers = require "nvim-lsp-installer.installers"
local shell = require "nvim-lsp-installer.installers.shell"

local M = {}

function M.download_file(url, out_file)
    return installers.when {
        unix = function(server, callback, context)
            process.spawn("wget", {
                args = { "-nv", "-O", out_file, url },
                cwd = server.root_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
        win = shell.powershell(("iwr -Uri %q -OutFile %q"):format(url, out_file)),
    }
end

function M.unzip(file, dest)
    return installers.pipe {
        installers.when {
            unix = function(server, callback, context)
                process.spawn("unzip", {
                    args = { "-d", dest, file },
                    cwd = server.root_dir,
                    stdio_sink = context.stdio_sink,
                }, callback)
            end,
            win = shell.powershell(("Expand-Archive -Path %q -DestinationPath %q"):format(file, dest)),
        },
        installers.always_succeed(M.delete_file(file)),
    }
end

function M.unzip_remote(url, dest)
    return installers.pipe {
        M.download_file(url, "archive.zip"),
        M.unzip("archive.zip", dest or "."),
    }
end

function M.untar(file)
    return installers.pipe {
        function(server, callback, context)
            process.spawn("tar", {
                args = { "-xvf", file },
                cwd = server.root_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
        installers.always_succeed(M.delete_file(file)),
    }
end

function M.untargz_remote(url)
    return installers.pipe {
        M.download_file(url, "archive.tar.gz"),
        M.gunzip "archive.tar.gz",
        M.untar "archive.tar",
    }
end

function M.gunzip(file)
    return function(server, callback, context)
        process.spawn("gzip", {
            args = { "-d", file },
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
end

function M.gunzip_remote(url, out_file)
    local archive = ("%s.gz"):format(out_file or "archive")
    return installers.pipe {
        M.download_file(url, archive),
        M.gunzip(archive),
        installers.always_succeed(M.delete_file(archive)),
    }
end

function M.delete_file(file)
    return installers.when {
        unix = function(server, callback, context)
            process.spawn("rm", {
                args = { "-f", file },
                cwd = server.root_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
        win = shell.powershell(("rm %q"):format(file)),
    }
end

function M.git_clone(repo_url)
    return function(server, callback, context)
        local c = process.chain {
            cwd = server.root_dir,
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

function M.gradlew(opts)
    return function(server, callback, context)
        process.spawn(path.concat { server.root_dir, platform.is_win and "gradlew.bat" or "gradlew" }, {
            args = opts.args,
            cwd = server.root_dir,
            stdio_sink = context.stdio_sink,
        }, callback)
    end
end

function M.ensure_executables(executables)
    return vim.schedule_wrap(function(_, callback, context)
        for i = 1, #executables do
            local entry = executables[i]
            local executable = entry[1]
            local error_msg = entry[2]
            if vim.fn.executable(executable) ~= 1 then
                context.stdio_sink.stderr(error_msg)
                callback(false)
                return
            end
        end
        callback(true)
    end)
end

function M.chmod(flags, files)
    return installers.on {
        unix = function(server, callback, context)
            process.spawn("chmod", {
                args = vim.list_extend({ flags }, files),
                cwd = server.root_dir,
                stdio_sink = context.stdio_sink,
            }, callback)
        end,
    }
end

return M
