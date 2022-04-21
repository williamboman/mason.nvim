require "nvim-lsp-installer.notify"(
    (
        "%s has been deprecated. See https://github.com/williamboman/nvim-lsp-installer/wiki/Async-infrastructure-changes-notice"
    ):format "nvim-lsp-installer.installers.context",
    vim.log.levels.WARN
)

local a = require "nvim-lsp-installer.core.async"
local log = require "nvim-lsp-installer.log"
local process = require "nvim-lsp-installer.process"
local installers = require "nvim-lsp-installer.installers"
local platform = require "nvim-lsp-installer.platform"
local fs = require "nvim-lsp-installer.fs"
local path = require "nvim-lsp-installer.path"
local github_client = require "nvim-lsp-installer.core.managers.github.client"

local M = {}

---@param repo string @The GitHub repo ("username/repo").
function M.use_github_latest_tag(repo)
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        context.github_repo = repo
        if context.requested_server_version then
            log.fmt_debug(
                "Requested server version already provided (%s), skipping fetching tags from GitHub.",
                context.requested_server_version
            )
            -- User has already provided a version - don't fetch the tags from GitHub
            return callback(true)
        end
        context.stdio_sink.stdout "Fetching tags from GitHub API...\n"
        a.run(github_client.fetch_latest_tag, function(success, result)
            if not success then
                context.stdio_sink.stderr(tostring(result) .. "\n")
                return callback(false)
            end
            result
                :on_success(function(latest_tag)
                    context.requested_server_version = latest_tag.name
                    callback(true)
                end)
                :on_failure(function(failure)
                    context.stdio_sink.stderr(tostring(failure) .. "\n")
                    callback(false)
                end)
        end, repo)
    end
end

---@param repo string @The GitHub repo ("username/repo").
---@param opts FetchLatestGithubReleaseOpts|nil
function M.use_github_release(repo, opts)
    opts = opts or {}
    ---@type ServerInstallerFunction
    return function(_, callback, context)
        context.github_repo = repo
        if context.requested_server_version then
            log.fmt_debug(
                "Requested server version already provided (%s), skipping fetching latest release from GitHub.",
                context.requested_server_version
            )
            -- User has already provided a version - don't fetch the latest version from GitHub
            return callback(true)
        end
        context.stdio_sink.stdout "Fetching latest release version from GitHub API...\n"
        a.run(github_client.fetch_latest_release, function(success, result)
            if not success then
                context.stdio_sink.stderr(tostring(result) .. "\n")
                return callback(false)
            end
            result
                :on_success(function(latest_release)
                    context.requested_server_version = latest_release.tag_name
                    callback(true)
                end)
                :on_failure(function(failure)
                    context.stdio_sink.stderr(tostring(failure) .. "\n")
                    callback(false)
                end)
        end, repo, opts)
    end
end

---@param repo string @The GitHub report ("username/repo").
---@param file string|fun(resolved_version: string): string @The name of a file available in the provided repo's GitHub releases.
---@param opts FetchLatestGithubReleaseOpts
function M.use_github_release_file(repo, file, opts)
    return installers.pipe {
        M.use_github_release(repo, opts),
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
                            "Could not find which release file to download. Most likely the current operating system, architecture (%s), or libc (%s) is not supported.\n"
                        ):format(platform.arch, platform.get_libc())
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
    return vim.schedule_wrap(function(server, callback, context)
        if server:promote_install_dir(context.install_dir) then
            context.install_dir = server.root_dir
            callback(true)
        else
            context.stdio_sink.stderr(
                ("Failed to promote temporary install directory to %s.\n"):format(server.root_dir)
            )
            callback(false)
        end
    end)
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

---@param fn fun(receipt_builder: InstallReceiptBuilder, ctx: ServerInstallContext)
function M.receipt(fn)
    return M.capture(function(ctx)
        fn(ctx.receipt, ctx)
        return installers.noop
    end)
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
        local new_dir = path.concat { context.install_dir, rel_path }
        log.fmt_debug(
            "Changing installation working directory for %s from %s to %s",
            server.name,
            context.install_dir,
            new_dir
        )
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

function M.use_os_distribution()
    ---Parses the provided contents of an /etc/\*-release file and identifies the Linux distribution.
    ---@param contents string @The contents of a /etc/\*-release file.
    ---@return table<string, any>
    local function parse_linux_dist(contents)
        local lines = vim.split(contents, "\n")

        local entries = {}

        for i = 1, #lines do
            local line = lines[i]
            local index = line:find "="
            if index then
                local key = line:sub(1, index - 1)
                local value = line:sub(index + 1)
                entries[key] = value
            end
        end

        if entries.ID == "ubuntu" then
            -- Parses the Ubuntu OS VERSION_ID into their version components, e.g. "18.04" -> {major=18, minor=04}
            local version_id = entries.VERSION_ID:gsub([["]], "")
            local version_parts = vim.split(version_id, "%.")
            local major = tonumber(version_parts[1])
            local minor = tonumber(version_parts[2])

            return {
                id = "ubuntu",
                version_id = version_id,
                version = { major = major, minor = minor },
            }
        else
            return {
                id = "linux-generic",
            }
        end
    end

    return installers.when {
        ---@type ServerInstallerFunction
        linux = function(_, callback, ctx)
            local stdio = process.in_memory_sink()
            process.spawn("bash", {
                args = { "-c", "cat /etc/*-release" },
                stdio_sink = stdio.sink,
            }, function(success)
                if success then
                    ctx.os_distribution = parse_linux_dist(table.concat(stdio.buffers.stdout, ""))
                    callback(true)
                else
                    ctx.os_distribution = {
                        id = "linux-generic",
                    }
                    callback(true)
                end
            end)
        end,
        mac = function(_, callback, ctx)
            ctx.os_distribution = {
                id = "macOS",
            }
            callback(true)
        end,
        win = function(_, callback, ctx)
            ctx.os_distribution = {
                id = "windows",
            }
            callback(true)
        end,
    }
end

function M.use_homebrew_prefix()
    return installers.on {
        mac = function(_, callback, ctx)
            local stdio = process.in_memory_sink()
            process.spawn("brew", {
                args = { "--prefix" },
                stdio_sink = stdio.sink,
            }, function(success)
                if success then
                    ctx.homebrew_prefix = vim.trim(table.concat(stdio.buffers.stdout, ""))
                    callback(true)
                else
                    ctx.stdio_sink.stderr "Failed to locate Homebrew installation.\n"
                    callback(false)
                end
            end)
        end,
    }
end

return M
