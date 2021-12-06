local Data = require "nvim-lsp-installer.data"
local log = require "nvim-lsp-installer.log"
local process = require "nvim-lsp-installer.process"
local installers = require "nvim-lsp-installer.installers"
local platform = require "nvim-lsp-installer.platform"
local fs = require "nvim-lsp-installer.fs"
local path = require "nvim-lsp-installer.path"

local M = {}

---@param url string @The url to fetch.
---@param callback fun(err: string|nil, raw_data: string)
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
            ("Write-Output (iwr -UseBasicParsing -Uri %q).Content"):format(url),
        }
        table.insert(
            job_variants,
            1,
            process.lazy_spawn("powershell.exe", {
                args = { "-NoProfile", "-Command", table.concat(ps_script, ";") },
                stdio_sink = stdio.sink,
                env = process.graft_env({}, { "PSMODULEPATH" }),
            })
        )
    end

    process.attempt {
        jobs = job_variants,
        on_iterate = function()
            log.debug "Flushing stdout/stderr buffers."
            stdio.buffers.stdout = {}
            stdio.buffers.stderr = {}
        end,
        on_finish = on_exit,
    }
end

---@param repo string @The GitHub repo ("username/repo").
function M.use_github_latest_tag(repo)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        if context.requested_server_version then
            log.fmt_debug(
                "Requested server version already provided (%s), skipping fetching tags from GitHub.",
                context.requested_server_version
            )
            -- User has already provided a version - don't fetch the tags from GitHub
            return callback(true)
        end
        context.stdio_sink.stdout "Fetching tags from GitHub API...\n"
        fetch(
            ("https://api.github.com/repos/%s/tags"):format(repo),
            vim.schedule_wrap(function(err, raw_data)
                if err then
                    context.stdio_sink.stderr(tostring(err) .. "\n")
                    callback(false)
                    return
                end

                local data = Data.json_decode(raw_data)
                if vim.tbl_count(data) == 0 then
                    context.stdio_sink.stderr("No tags found for GitHub repo %s.\n", repo)
                    callback(false)
                    return
                end
                context.requested_server_version = data[1].name
                callback(true)
            end)
        )
    end
end

---@param repo string @The GitHub repo ("username/repo").
function M.use_github_release(repo)
    ---@type ServerInstallerFunction
    return function(server, callback, context)
        if context.requested_server_version then
            log.fmt_debug(
                "Requested server version already provided (%s), skipping fetching latest release from GitHub.",
                context.requested_server_version
            )
            -- User has already provided a version - don't fetch the latest version from GitHub
            return callback(true)
        end
        context.stdio_sink.stdout "Fetching latest release version from GitHub API...\n"
        fetch(
            ("https://api.github.com/repos/%s/releases/latest"):format(repo),
            vim.schedule_wrap(function(err, response)
                if err then
                    context.stdio_sink.stderr(tostring(err) .. "\n")
                    return callback(false)
                end
                local version = Data.json_decode(response).tag_name
                log.debug("Resolved latest version", server.name, repo, version)
                context.requested_server_version = version
                callback(true)
            end)
        )
    end
end

---@param repo string @The GitHub report ("username/repo").
---@param file string|fun(resolved_version: string): string @The name of a file available in the provided repo's GitHub releases.
function M.use_github_release_file(repo, file)
    return installers.pipe {
        M.use_github_release(repo),
        function(server, callback, context)
            local function get_download_url(version)
                local target_file
                if type(file) == "function" then
                    target_file = file(version)
                else
                    target_file = file
                end
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

            local download_url = get_download_url(context.requested_server_version)
            if not download_url then
                return callback(false)
            end
            context.github_release_file = download_url
            callback(true)
        end,
    }
end

---Creates an installer that moves the current installation directory to the server's root directory.
function M.promote_install_dir()
    ---@type ServerInstallerFunction
    return function(server, callback, context)
        if server:promote_install_dir(context.install_dir) then
            context.install_dir = server.root_dir
            callback(true)
        else
            context.stdio_sink.stderr(
                ("Failed to promote temporary install directory to %s.\n"):format(server.root_dir)
            )
            callback(false)
        end
    end
end

---Access the context ojbect to create a new installer.
---@param fn fun(context: ServerInstallContext): ServerInstallerFunction
function M.capture(fn)
    ---@type ServerInstallerFunction
    return function(server, callback, context)
        local installer = fn(context)
        installer(server, callback, context)
    end
end

---Update the context object.
---@param fn fun(context: ServerInstallContext): ServerInstallerFunction
function M.set(fn)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        fn(context)
        callback(true)
    end
end

---@param rel_path string @The relative path from the current installation working directory.
function M.set_working_dir(rel_path)
    ---@type ServerInstallerFunction
    return vim.schedule_wrap(function(server, callback, context)
        log.fmt_debug("Changing installation working directory for %s", server.name)
        local new_dir = path.concat { context.install_dir, rel_path }
        if not fs.dir_exists(new_dir) then
            local ok = pcall(fs.mkdirp, new_dir)
            if not ok then
                context.stdio_sink.stderr(("Failed to create directory %s.\n"):format(new_dir))
                return callback(false)
            end
        end
        context.install_dir = new_dir
        callback(true)
    end)
end

return M
