local eclipse = require "nvim-lsp-installer.core.clients.eclipse"

---@async
---@param receipt InstallReceipt
return function(receipt)
    return eclipse.fetch_latest_jdtls_version():map_catching(function(latest_version)
        if receipt.primary_source.version ~= latest_version then
            return {
                name = "jdtls",
                current_version = receipt.primary_source.version,
                latest_version = latest_version,
            }
        end
        error "Primary package is not outdated."
    end)
end
