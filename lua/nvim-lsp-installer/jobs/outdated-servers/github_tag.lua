local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local github = require "nvim-lsp-installer.core.clients.github"

local fetch_latest_tag = a.promisify(github.fetch_latest_tag, true)

---@async
---@param receipt InstallReceipt
return function(receipt)
    local source = receipt.primary_source
    return Result.run_catching(function()
        local latest_tag = fetch_latest_tag(source.repo)

        if source.tag ~= latest_tag.name then
            return {
                name = source.repo,
                current_version = source.tag,
                latest_version = latest_tag.name,
            }
        end
        error "Primary package is not outdated."
    end)
end
