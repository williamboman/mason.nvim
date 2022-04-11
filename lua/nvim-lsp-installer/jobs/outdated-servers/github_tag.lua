local github_client = require "nvim-lsp-installer.core.managers.github.client"

---@async
---@param receipt InstallReceipt
return function(receipt)
    local source = receipt.primary_source
    return github_client.fetch_latest_tag(source.repo):map_catching(
        ---@param latest_tag GitHubTag
        function(latest_tag)
            if source.tag ~= latest_tag.name then
                return {
                    name = source.repo,
                    current_version = source.tag,
                    latest_version = latest_tag.name,
                }
            end
            error "Primary package is not outdated."
        end
    )
end
