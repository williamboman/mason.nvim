local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local github = require "nvim-lsp-installer.core.clients.github"

local fetch_latest_release = a.promisify(github.fetch_latest_release, true)

---@async
---@param receipt InstallReceipt
return function(receipt)
    local source = receipt.primary_source
    return Result.run_catching(function()
        local latest_release = fetch_latest_release(source.repo, { tag_name_pattern = source.tag_name_pattern })
        if source.release ~= latest_release.tag_name then
            return {
                name = source.repo,
                current_version = source.release,
                latest_version = latest_release.tag_name,
            }
        end
        error "Primary package is not outdated."
    end)
end
