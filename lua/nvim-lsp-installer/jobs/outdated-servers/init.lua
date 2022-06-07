local a = require "nvim-lsp-installer.core.async"
local JobExecutionPool = require "nvim-lsp-installer.jobs.pool"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"
local log = require "nvim-lsp-installer.log"

local npm = require "nvim-lsp-installer.core.managers.npm"
local pip3 = require "nvim-lsp-installer.core.managers.pip3"
local git = require "nvim-lsp-installer.core.managers.git"
local gem = require "nvim-lsp-installer.core.managers.gem"
local go = require "nvim-lsp-installer.core.managers.go"
local cargo = require "nvim-lsp-installer.core.managers.cargo"
local github = require "nvim-lsp-installer.core.managers.github"
local composer = require "nvim-lsp-installer.core.managers.composer"
local jdtls_check = require "nvim-lsp-installer.jobs.outdated-servers.jdtls"
local luarocks = require "nvim-lsp-installer.core.managers.luarocks"

local M = {}

local jobpool = JobExecutionPool:new {
    size = 4,
}

---@type table<InstallReceiptSourceType, async fun(receipt: InstallReceipt, install_dir: string): Result>
local checkers = {
    ["npm"] = npm.check_outdated_primary_package,
    ["pip3"] = pip3.check_outdated_primary_package,
    ["git"] = git.check_outdated_git_clone,
    ["cargo"] = cargo.check_outdated_primary_package,
    ["composer"] = composer.check_outdated_primary_package,
    ["gem"] = gem.check_outdated_primary_package,
    ["go"] = go.check_outdated_primary_package,
    ["luarocks"] = luarocks.check_outdated_primary_package,
    ["jdtls"] = jdtls_check,
    ["github_release_file"] = github.check_outdated_primary_package_release,
    ["github_release"] = github.check_outdated_primary_package_release,
    ["github_tag"] = github.check_outdated_primary_package_tag,
}

local pending_servers = {}

---@alias VersionCheckResultProgress {completed: integer, total: integer}

---@param servers Server[]
---@param on_result fun(result: VersionCheckResult, progress: VersionCheckResultProgress)
function M.identify_outdated_servers(servers, on_result)
    local total_checks = #servers
    local completed_checks = 0
    for _, server in ipairs(servers) do
        if not pending_servers[server.name] then
            pending_servers[server.name] = true
            jobpool:supply(function(_done)
                local function complete(result)
                    completed_checks = completed_checks + 1
                    pending_servers[server.name] = nil
                    on_result(result, { completed = completed_checks, total = total_checks })
                    _done()
                end

                local receipt = server:get_receipt()
                if receipt then
                    if
                        vim.tbl_contains({ "github_release_file", "github_tag" }, receipt.primary_source.type)
                        and receipt.schema_version == "1.0"
                    then
                        -- Receipts of this version are in some cases incomplete.
                        return complete(VersionCheckResult.fail(server))
                    end

                    local checker = checkers[receipt.primary_source.type]
                    if checker then
                        a.run(checker, function(success, result)
                            if success and result:is_success() then
                                complete(VersionCheckResult.success(server, { result:get_or_nil() }))
                            else
                                complete(VersionCheckResult.fail(server))
                            end
                        end, receipt, server.root_dir)
                    else
                        complete(VersionCheckResult.empty(server))
                        log.fmt_debug("Unable to find checker for source=%s", receipt.primary_source.type)
                    end
                else
                    complete(VersionCheckResult.empty(server))
                    log.fmt_trace("No receipt found for server=%s", server.name)
                end
            end)
        else
            completed_checks = completed_checks + 1
            on_result(VersionCheckResult.fail(server), { completed = completed_checks, total = total_checks })
        end
    end
end

return M
