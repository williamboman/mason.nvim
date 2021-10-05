local Data = require "nvim-lsp-installer.data"
local log = require "nvim-lsp-installer.log"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"

local M = {}

local function fetch(url, callback)
    local stdio = process.in_memory_sink()
    log.fmt_debug("Fetching URL %s", url)
    local on_exit = function(success)
        if success then
            log.fmt_debug("Successfully fetched URL %s", url)
            callback(nil, table.concat(stdio.buffers.stdout, ""))
        else
            local stderr = table.concat(stdio.buffers.stderr, "")
            log.fmt_warn("Failed to fetch URL %s. stderr=%s", url, stderr)
            callback(("Failed to fetch url %q.\n%s"):format(url, stderr), nil)
        end
    end

    local job_variants = {
        process.lazy_spawn("wget", {
            args = { "-nv", "-O", "-", url },
            stdio_sink = stdio.sink,
        }),
        process.lazy_spawn("curl", {
            args = { "-fsSL", url },
            stdio_sink = stdio.sink,
        }),
    }

    if platform.is_win then
        local ps_script = {
            "$ProgressPreference = 'SilentlyContinue'",
            ("Write-Output (iwr -Uri %q).Content"):format(url),
        }
        table.insert(
            job_variants,
            1,
            process.lazy_spawn("powershell.exe", {
                args = { "-Command", table.concat(ps_script, ";") },
                stdio_sink = stdio.sink,
            })
        )
    end

    process.attempt {
        jobs = job_variants,
        on_iterate = function()
            log.debug("Flushing stdout/stderr buffers.")
            stdio.buffers.stdout = {}
            stdio.buffers.stderr = {}
        end,
        on_finish = on_exit,
    }
end

function M.github_release_file(repo, file)
    return function(server, callback, context)
        local function get_download_url(version)
            local target_file = type(file) == "function" and file(version) or file
            if not target_file then
                log.fmt_error(
                    "Unable to find which release file to download. server_name=%s, repo=%s",
                    server.name,
                    repo
                )
                context.stdio_sink.stderr(
                    (
                        "Could not find which release file to download. Most likely, the current operating system or architecture (%s) is not supported.\n"
                    ):format(platform.arch)
                )
                return nil
            end

            return ("https://github.com/%s/releases/download/%s/%s"):format(repo, version, target_file)
        end
        if context.requested_server_version then
            -- User has already provided a version - don't fetch the latest version from GitHub
            local download_url = get_download_url(context.requested_server_version)
            if not download_url then
                return callback(false)
            end
            context.github_release_file = download_url
            callback(true)
        else
            context.stdio_sink.stdout "Fetching latest release version from GitHub API...\n"
            fetch(
                ("https://api.github.com/repos/%s/releases/latest"):format(repo),
                vim.schedule_wrap(function(err, response)
                    if err then
                        context.stdio_sink.stderr(tostring(err))
                        return callback(false)
                    end
                    local version = Data.json_decode(response).tag_name
                    log.debug("Resolved latest version", server.name, version)
                    context.requested_server_version = version
                    local download_url = get_download_url(version)
                    if not download_url then
                        return callback(false)
                    end
                    context.github_release_file = download_url
                    callback(true)
                end)
            )
        end
    end
end

function M.capture(fn)
    return function(server, callback, context, ...)
        local installer = fn(context)
        installer(server, callback, context, ...)
    end
end

function M.set(fn)
    return function(_, callback, context)
        fn(context)
        callback(true)
    end
end

return M
