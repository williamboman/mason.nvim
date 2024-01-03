local _ = require "mason-core.functional"
local fetch = require "mason-core.fetch"
local semver = require "mason-core.semver"

---@param path string
local function api_url(path)
    return ("https://open-vsx.org/api/%s"):format(path)
end

---@param version string
local function maybe_semver_sort(version)
    return semver.parse(version):get_or_else(version)
end

---@type OpenVSXProvider
return {
    get_latest_version = function(namespace, extension)
        return fetch(api_url("%s/%s"):format(namespace, extension)):map_catching(vim.json.decode):map(_.prop "version")
    end,
    get_all_versions = function(namespace, extension)
        return fetch(api_url("%s/%s/versions"):format(namespace, extension))
            :map_catching(vim.json.decode)
            :map(_.compose(_.keys, _.prop "versions"))
            :map(_.compose(_.reverse, _.sort_by(maybe_semver_sort)))
    end,
}
