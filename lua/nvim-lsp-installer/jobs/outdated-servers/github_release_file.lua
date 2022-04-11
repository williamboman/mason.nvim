local github_client = require "nvim-lsp-installer.core.managers.github.client"

---@async
---@param receipt InstallReceipt
return function(receipt)
    local source = receipt.primary_source
    return github_client.fetch_latest_release(source.repo, { tag_name_pattern = source.tag_name_pattern }):map_catching(
        ---@param latest_release GitHubRelease
        function(latest_release)
            if source.release ~= latest_release.tag_name then
                return {
                    name = source.repo,
                    current_version = source.release,
                    latest_version = latest_release.tag_name,
                }
            end
            error "Primary package is not outdated."
        end
    )
end
