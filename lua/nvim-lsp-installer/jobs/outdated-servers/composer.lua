local process = require "nvim-lsp-installer.process"
local composer = require "nvim-lsp-installer.installers.composer"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"

---@param server Server
---@param source InstallReceiptSource
---@param on_check_complete fun(result: VersionCheckResult)
local function composer_checker(server, source, on_check_complete)
    local stdio = process.in_memory_sink()
    process.spawn(composer.composer_cmd, {
        args = { "outdated", "--no-interaction", "--format=json" },
        cwd = server.root_dir,
        stdio_sink = stdio.sink,
    }, function(success)
        if not success then
            return on_check_complete(VersionCheckResult.fail(server))
        end
        ---@type {installed: {name: string, version: string, latest: string}[]}
        local decode_ok, outdated_json = pcall(vim.json.decode, table.concat(stdio.buffers.stdout, ""))

        if not decode_ok then
            return on_check_complete(VersionCheckResult.fail(server))
        end

        ---@type OutdatedPackage[]
        local outdated_packages = {}

        for _, outdated_package in ipairs(outdated_json.installed) do
            if outdated_package.name == source.package and outdated_package.version ~= outdated_package.latest then
                table.insert(outdated_packages, {
                    name = outdated_package.name,
                    current_version = outdated_package.version,
                    latest_version = outdated_package.latest,
                })
            end
        end

        on_check_complete(VersionCheckResult.success(server, outdated_packages))
    end)
end

return composer_checker
