local a = require "nvim-lsp-installer.core.async"
local Result = require "nvim-lsp-installer.core.result"
local eclipse = require "nvim-lsp-installer.core.clients.eclipse"

local fetch_latest_jdtls_version = a.promisify(eclipse.fetch_latest_jdtls_version, true)

---@async
---@param receipt InstallReceipt
return function(receipt)
    return Result.run_catching(function()
        local latest_version = fetch_latest_jdtls_version()
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
