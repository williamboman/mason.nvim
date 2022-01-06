local process = require "nvim-lsp-installer.process"
local pip3 = require "nvim-lsp-installer.installers.pip3"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"
local log = require "nvim-lsp-installer.log"

---@param package string
---@return string
local function normalize_package(package)
    -- https://stackoverflow.com/a/60307740
    local s = package:gsub("%[.*%]", "")
    return s
end

---@param server Server
---@param source InstallReceiptSource
---@param on_check_complete fun(result: VersionCheckResult)
local function pip3_check(server, source, on_check_complete)
    local normalized_package = normalize_package(source.package)
    log.fmt_trace("Normalized package from %s to %s.", source.package, normalized_package)
    local stdio = process.in_memory_sink()
    process.spawn(
        "python",
        {
            args = { "-m", "pip", "list", "--outdated", "--format=json" },
            cwd = server.root_dir,
            stdio_sink = stdio.sink,
            env = process.graft_env(pip3.env(server.root_dir)),
        },
        vim.schedule_wrap(function(success)
            if not success then
                return on_check_complete(VersionCheckResult.fail(server))
            end
            ---@alias PipOutdatedPackage {name: string, version: string, latest_version: string}
            ---@type PipOutdatedPackage[]
            local ok, packages = pcall(vim.json.decode, table.concat(stdio.buffers.stdout, ""))

            if not ok then
                log.fmt_error("Failed to parse pip3 output. %s", packages)
                return on_check_complete(VersionCheckResult.fail(server))
            end

            log.trace("Outdated packages", packages)

            ---@type OutdatedPackage[]
            local outdated_packages = {}

            for _, outdated_package in ipairs(packages) do
                if
                    outdated_package.name == normalized_package
                    and outdated_package.version ~= outdated_package.latest_version
                then
                    table.insert(outdated_packages, {
                        name = outdated_package.name,
                        current_version = outdated_package.version,
                        latest_version = outdated_package.latest_version,
                    })
                end
            end

            on_check_complete(VersionCheckResult.success(server, outdated_packages))
        end)
    )
end

-- to allow tests to access internals
return setmetatable({
    normalize_package = normalize_package,
}, {
    __call = function(_, ...)
        return pip3_check(...)
    end,
})
