local log = require "nvim-lsp-installer.log"
local process = require "nvim-lsp-installer.process"
local platform = require "nvim-lsp-installer.platform"

local USER_AGENT = "nvim-lsp-installer (+https://github.com/williamboman/nvim-lsp-installer)"

local HEADERS = {
    wget = { "--header", ("User-Agent: %s"):format(USER_AGENT) },
    curl = { "-H", ("User-Agent: %s"):format(USER_AGENT) },
    iwr = ("-Headers @{'User-Agent' = '%s'}"):format(USER_AGENT),
}

local function with_headers(headers, args)
    local result = {}
    vim.list_extend(result, headers)
    vim.list_extend(result, args)
    return result
end

---@alias FetchCallback fun(err: string|nil, raw_data: string)

---@param url string The url to fetch.
---@param callback_or_opts FetchCallback|{custom_fetcher: { cmd: string, args: string[] }}
---@param callback FetchCallback
local function fetch(url, callback_or_opts, callback)
    local opts = type(callback_or_opts) == "table" and callback_or_opts or {}
    callback = type(callback_or_opts) == "function" and callback_or_opts or callback
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
            args = with_headers(HEADERS.wget, { "-nv", "-O", "-", url }),
            stdio_sink = stdio.sink,
        }),
        process.lazy_spawn("curl", {
            args = with_headers(HEADERS.curl, { "-fsSL", url }),
            stdio_sink = stdio.sink,
        }),
    }

    if platform.is_win then
        local ps_script = {
            "$ProgressPreference = 'SilentlyContinue';",
            "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;",
            ("Write-Output (iwr %s -UseBasicParsing -Uri %q).Content"):format(HEADERS.iwr, url),
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

return setmetatable({
    with_headers = with_headers,
    HEADERS = HEADERS,
}, {
    __call = function(_, ...)
        return fetch(...)
    end,
})
