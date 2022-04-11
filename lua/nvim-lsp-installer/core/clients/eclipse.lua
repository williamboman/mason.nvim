local fetch = require "nvim-lsp-installer.core.fetch"
local M = {}

---@param version string The version string as found in the latest.txt endpoint.
---@return string The parsed version number.
function M._parse_jdtls_version_string(version)
    return vim.trim(version):gsub("^jdt%-language%-server%-", ""):gsub("%.tar%.gz$", "")
end

---@async
function M.fetch_latest_jdtls_version()
    return fetch("https://download.eclipse.org/jdtls/snapshots/latest.txt"):map(M._parse_jdtls_version_string)
end

return M
