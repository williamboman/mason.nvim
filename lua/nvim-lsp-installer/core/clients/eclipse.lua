local fetch = require "nvim-lsp-installer.core.fetch"
local M = {}

---@param version string The version string as found in the latest.txt endpoint.
---@return string The parsed version number.
function M._parse_jdtls_version_string(version)
    return vim.trim(version):gsub("^jdt%-language%-server%-", ""):gsub("%.tar%.gz$", "")
end

---@param callback fun(err: string|nil, data: string|nil)
function M.fetch_latest_jdtls_version(callback)
    fetch("https://download.eclipse.org/jdtls/snapshots/latest.txt", function(err, data)
        if err then
            callback(err, nil)
        else
            callback(nil, M._parse_jdtls_version_string(data))
        end
    end)
end

return M
