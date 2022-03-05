local process = require "nvim-lsp-installer.process"
local gem = require "nvim-lsp-installer.installers.gem"
local log = require "nvim-lsp-installer.log"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"

local function not_empty(s)
    return s ~= nil and s ~= ""
end

---Parses a string input like "package (0.1.0 < 0.2.0)" into its components
---@param outdated_gem string
---@return GemOutdatedPackage
local function parse_outdated_gem(outdated_gem)
    local package_name, version_expression = outdated_gem:match "^(.+) %((.+)%)"
    if not package_name or not version_expression then
        -- unparseable
        return nil
    end
    local current_version, latest_version = unpack(vim.split(version_expression, "<"))

    ---@alias GemOutdatedPackage {name:string, current_version: string, latest_version: string}
    local outdated_package = {
        name = vim.trim(package_name),
        current_version = vim.trim(current_version),
        latest_version = vim.trim(latest_version),
    }
    return outdated_package
end

---@param output string
local function parse_gem_list_output(output)
    ---@type Record<string, string>
    local gem_versions = {}
    for _, line in ipairs(vim.split(output, "\n")) do
        local gem_package, version = line:match "^(%S+) %((%S+)%)$"
        if gem_package and version then
            gem_versions[gem_package] = version
        end
    end
    return gem_versions
end

---@param server Server
---@param source InstallReceiptSource
---@param on_check_complete fun(result: VersionCheckResult)
local function gem_checker(server, source, on_check_complete)
    local stdio = process.in_memory_sink()
    process.spawn(
        "gem",
        {
            args = { "outdated" },
            cwd = server.root_dir,
            stdio_sink = stdio.sink,
            env = process.graft_env(gem.env(server.root_dir)),
        },
        vim.schedule_wrap(function(success)
            if not success then
                return on_check_complete(VersionCheckResult.fail(server))
            end
            ---@type string[]
            local lines = vim.split(table.concat(stdio.buffers.stdout, ""), "\n")
            log.trace("Gem outdated lines output", lines)
            local outdated_gems = vim.tbl_map(parse_outdated_gem, vim.tbl_filter(not_empty, lines))
            log.trace("Gem outdated packages", outdated_gems)

            ---@type OutdatedPackage[]
            local outdated_packages = {}

            for _, outdated_gem in ipairs(outdated_gems) do
                if
                    outdated_gem.name == source.package
                    and outdated_gem.current_version ~= outdated_gem.latest_version
                then
                    table.insert(outdated_packages, {
                        name = outdated_gem.name,
                        current_version = outdated_gem.current_version,
                        latest_version = outdated_gem.latest_version,
                    })
                end
            end

            on_check_complete(VersionCheckResult.success(server, outdated_packages))
        end)
    )
end

-- to allow tests to access internals
return setmetatable({
    parse_outdated_gem = parse_outdated_gem,
    parse_gem_list_output = parse_gem_list_output,
}, {
    __call = function(_, ...)
        return gem_checker(...)
    end,
})
