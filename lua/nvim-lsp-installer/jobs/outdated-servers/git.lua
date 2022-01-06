local process = require "nvim-lsp-installer.process"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"

---@param server Server
---@param source InstallReceiptSource
---@param on_check_complete fun(result: VersionCheckResult)
return function(server, source, on_check_complete)
    process.spawn("git", {
        -- We assume git installation track the remote HEAD branch
        args = { "fetch", "origin", "HEAD" },
        cwd = server.root_dir,
        stdio_sink = process.empty_sink(),
    }, function(fetch_success)
        local stdio = process.in_memory_sink()
        if not fetch_success then
            return on_check_complete(VersionCheckResult.fail(server))
        end
        process.spawn("git", {
            args = { "rev-parse", "FETCH_HEAD", "HEAD" },
            cwd = server.root_dir,
            stdio_sink = stdio.sink,
        }, function(success)
            if success then
                local stdout = table.concat(stdio.buffers.stdout, "")
                local remote_head, local_head = unpack(vim.split(stdout, "\n"))
                if remote_head ~= local_head then
                    on_check_complete(VersionCheckResult.success(server, {
                        {
                            name = source.remote,
                            latest_version = remote_head,
                            current_version = local_head,
                        },
                    }))
                else
                    on_check_complete(VersionCheckResult.empty(server))
                end
            else
                on_check_complete(VersionCheckResult.fail(server))
            end
        end)
    end)
end
