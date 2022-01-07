local log = require "nvim-lsp-installer.log"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"

---@param url string The url to fetch.
---@param callback fun(err: string|nil, raw_data: string)
---@param opts {custom_fetcher: { cmd: string, args: string[] }}
local function fetch(url, callback, opts)
    opts = opts or {}
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

    if opts.custom_fetcher then
        table.insert(
            job_variants,
            1,
            process.lazy_spawn(opts.custom_fetcher.cmd, {
                args = opts.custom_fetcher.args,
                stdio_sink = stdio.sink,
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

return fetch
