local JobExecutionPool = require "nvim-lsp-installer.jobs.pool"
local VersionCheckResult = require "nvim-lsp-installer.jobs.outdated-servers.version-check-result"
local log = require "nvim-lsp-installer.log"

local npm_check = require "nvim-lsp-installer.jobs.outdated-servers.npm"
local cargo_check = require "nvim-lsp-installer.jobs.outdated-servers.cargo"
local pip3_check = require "nvim-lsp-installer.jobs.outdated-servers.pip3"
local gem_check = require "nvim-lsp-installer.jobs.outdated-servers.gem"
local git_check = require "nvim-lsp-installer.jobs.outdated-servers.git"
local github_release_file_check = require "nvim-lsp-installer.jobs.outdated-servers.github_release_file"
local github_tag_check = require "nvim-lsp-installer.jobs.outdated-servers.github_tag"
local jdtls = require "nvim-lsp-installer.jobs.outdated-servers.jdtls"
local composer_check = require "nvim-lsp-installer.jobs.outdated-servers.composer"

local M = {}

local jobpool = JobExecutionPool:new {
    size = 4,
}

local function noop(server, _, on_result)
    on_result(VersionCheckResult.empty(server))
end

---@type Record<InstallReceiptSourceType, function>
local checkers = {
    ["npm"] = npm_check,
    ["pip3"] = pip3_check,
    ["cargo"] = cargo_check,
    ["gem"] = gem_check,
    ["composer"] = composer_check,
    ["go"] = noop, -- TODO
    ["dotnet"] = noop, -- TODO
    ["r_package"] = noop, -- TODO
    ["unmanaged"] = noop,
    ["system"] = noop,
    ["jdtls"] = jdtls,
    ["git"] = git_check,
    ["github_release_file"] = github_release_file_check,
    ["github_tag"] = github_tag_check,
    ["opam"] = noop,
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
                        checker(server, receipt.primary_source, complete)
                    else
                        complete(VersionCheckResult.empty(server))
                        log.fmt_error("Unable to find checker for source=%s", receipt.primary_source.type)
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
