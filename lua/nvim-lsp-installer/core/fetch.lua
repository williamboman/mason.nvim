local log = require "nvim-lsp-installer.log"
local platform = require "nvim-lsp-installer.core.platform"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"
local powershell = require "nvim-lsp-installer.core.managers.powershell"

local USER_AGENT = "nvim-lsp-installer (+https://github.com/williamboman/nvim-lsp-installer)"

local HEADERS = {
    wget = { "--header", ("User-Agent: %s"):format(USER_AGENT) },
    curl = { "-H", ("User-Agent: %s"):format(USER_AGENT) },
    iwr = ("-Headers @{'User-Agent' = '%s'}"):format(USER_AGENT),
}

---@alias FetchOpts {out_file:string}

---@async
---@param url string @The url to fetch.
---@param opts FetchOpts
local function fetch(url, opts)
    opts = opts or {}
    log.fmt_debug("Fetching URL %s", url)

    local platform_specific = Result.failure()

    if platform.is_win then
        if opts.out_file then
            platform_specific = powershell.command(
                ([[iwr %s -UseBasicParsing -Uri %q -OutFile %q;]]):format(HEADERS.iwr, url, opts.out_file)
            )
        else
            platform_specific = powershell.command(
                ([[Write-Output (iwr %s -UseBasicParsing -Uri %q).Content;]]):format(HEADERS.iwr, url)
            )
        end
    end

    return platform_specific
        :recover_catching(function()
            return spawn.wget({ HEADERS.wget, "-nv", "-O", opts.out_file or "-", url }):get_or_throw()
        end)
        :recover_catching(function()
            return spawn.curl({ HEADERS.curl, "-fsSL", opts.out_file and { "-o", opts.out_file } or vim.NIL, url }):get_or_throw()
        end)
        :map(function(result)
            if opts.out_file then
                return result
            else
                return result.stdout
            end
        end)
end

return fetch
