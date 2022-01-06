local process = require "nvim-lsp-installer.process"
local npm = require "nvim-lsp-installer.installers.npm"
local log = require "nvim-lsp-installer.log"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"

---@param server Server
---@param source InstallReceiptSource
---@param on_check_complete fun(result: VersionCheckResult)
return function(server, source, on_check_complete)
    local stdio = process.in_memory_sink()
    process.spawn(
        npm.npm_command,
        {
            args = vim.list_extend({ "outdated", "--json" }, { source.package }),
            cwd = server.root_dir,
            stdio_sink = stdio.sink,
        },
        -- Note that `npm outdated` exits with code 1 if it finds outdated packages
        vim.schedule_wrap(function()
            ---@alias NpmOutdatedPackage {current: string, wanted: string, latest: string, dependent: string, location: string}
            ---@type table<string, NpmOutdatedPackage>
            local ok, data = pcall(vim.json.decode, table.concat(stdio.buffers.stdout, ""))

            if not ok then
                log.fmt_error("Failed to parse npm outdated --json output. %s", data)
                return on_check_complete(VersionCheckResult.fail(server))
            end

            ---@type OutdatedPackage[]
            local outdated_packages = {}

            for package, outdated_package in pairs(data) do
                if outdated_package.current ~= outdated_package.latest then
                    table.insert(outdated_packages, {
                        name = package,
                        current_version = outdated_package.current,
                        latest_version = outdated_package.latest,
                    })
                end
            end

            on_check_complete(VersionCheckResult.success(server, outdated_packages))
        end)
    )
end
