local github = require "nvim-lsp-installer.core.clients.github"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"

---@param server Server
---@param source InstallReceiptSource
---@param on_result fun(result: VersionCheckResult)
return function(server, source, on_result)
    github.fetch_latest_tag(source.repo, function(err, latest_tag)
        if err then
            return on_result(VersionCheckResult.fail(server))
        end

        if source.tag ~= latest_tag.name then
            return on_result(VersionCheckResult.success(server, {
                {
                    name = source.repo,
                    current_version = source.tag,
                    latest_version = latest_tag.name,
                },
            }))
        else
            return on_result(VersionCheckResult.empty(server))
        end
    end)
end
