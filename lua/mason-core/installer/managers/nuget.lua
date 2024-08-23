local Result = require "mason-core.result"
local installer = require "mason-core.installer"
local log = require "mason-core.log"
local platform = require "mason-core.platform"
local fetch = require "mason-core.fetch"
local common = require "mason-core.installer.managers.common"

local M = {}

---@async
---@param package string
---@param version string
---@nodiscard
function M.install(package, version, repository_url)
    log.fmt_debug("nuget: install %s %s", package, version)
    local ctx = installer.context()

    local index_file = M.fetch_nuget_index_file(repository_url):get_or_throw()

    assert(index_file, "nuget index file could not be retrieved")

    local resource = vim.iter(index_file.resources)
        :find(function (v)
            return v['@type'] == 'PackageBaseAddress/3.0.0'
        end)

    assert(resource, "could not get PackageBaseAddress resource from nuget index file")

    local nupkg_download_url = string.format("%s%s/%s/%s.%s.nupkg",
        resource["@id"],
        package:lower(),
        version,
        package:lower(),
        version)

    ctx.stdio_sink.stdout(("Installing nuget package %s@%s…\n"):format(package, version))

    local download_item = {
        download_url = nupkg_download_url,
        out_file = string.format("%s-%s.nupkg", package, version)
    }

    return common.download_files(ctx, { download_item })
end

---@alias NugetIndexResource { '@id': string, '@type': string}
---@alias NugetIndexFile { version: string, resources: NugetIndexResource[]}

---@async
---@param repository_url string
---@return Result # Result<NugetIndexFile>
function M.fetch_nuget_index_file(repository_url)
    return fetch(repository_url, {
        headers = {
            Accept = "application/json",
        },
    }):map_catching(vim.json.decode)
end

---@param bin string
function M.bin_path(bin)
    return Result.pcall(platform.when, {
        unix = function()
            return bin
        end,
        win = function()
            return ("%s.exe"):format(bin)
        end,
    })
end

return M
