local log = require "nvim-lsp-installer.log"
local platform = require "nvim-lsp-installer.platform"
local Result = require "nvim-lsp-installer.core.result"
local spawn = require "nvim-lsp-installer.core.spawn"
local powershell = require "nvim-lsp-installer.core.managers.powershell"

local USER_AGENT = "nvim-lsp-installer (+https://github.com/williamboman/nvim-lsp-installer)"

local HEADERS = {
    wget = { "--header", ("User-Agent: %s"):format(USER_AGENT) },
    curl = { "-H", ("User-Agent: %s"):format(USER_AGENT) },
    iwr = ("-Headers @{'User-Agent' = '%s'}"):format(USER_AGENT),
}

---@async
---@param url string @The url to fetch.
local function fetch(url)
    log.fmt_debug("Fetching URL %s", url)

    local platform_specific = Result.failure()

    if platform.is_win then
        platform_specific = powershell.command(
            ([[Write-Output (iwr %s -UseBasicParsing -Uri %q).Content;]]):format(HEADERS.iwr, url)
        )
    end

    return platform_specific
        :recover_catching(function()
            return spawn.wget({ HEADERS.wget, "-nv", "-O", "-", url }):get_or_throw()
        end)
        :recover_catching(function()
            return spawn.curl({ HEADERS.curl, "-fsSL", url }):get_or_throw()
        end)
        :map(function(result)
            return result.stdout
        end)
end

return fetch
