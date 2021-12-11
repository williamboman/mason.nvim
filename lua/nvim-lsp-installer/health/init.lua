local health = require "health"
local process = require "nvim-lsp-installer.process"
local gem = require "nvim-lsp-installer.installers.gem"
local composer = require "nvim-lsp-installer.installers.composer"
local npm = require "nvim-lsp-installer.installers.npm"
local platform = require "nvim-lsp-installer.platform"
local Data = require "nvim-lsp-installer.data"

local when = Data.when

local M = {}

---@alias HealthCheckResult
---| '"success"'
---| '"version-mismatch"'
---| '"not-available"'

---@class HealthCheck
---@field public result HealthCheckResult
---@field public version string|nil
---@field public reason string|nil
---@field public name string
local HealthCheck = {}
HealthCheck.__index = HealthCheck

function HealthCheck.new(props)
    local self = setmetatable(props, HealthCheck)
    return self
end

---@param callback fun(result: HealthCheck)
local function mk_healthcheck(callback)
    ---@param opts {cmd:string, args:string[], name: string, use_stderr:boolean}
    return function(opts)
        return function()
            local stdio = process.in_memory_sink()
            process.spawn(opts.cmd, {
                args = opts.args,
                stdio_sink = stdio.sink,
            }, function(success)
                if success then
                    local version = vim.split(
                        table.concat(opts.use_stderr and stdio.buffers.stderr or stdio.buffers.stdout, ""),
                        "\n"
                    )[1]

                    if opts.check then
                        local version_check = opts.check(version)
                        if version_check then
                            callback(HealthCheck.new {
                                result = "version-mismatch",
                                reason = version_check,
                                version = version,
                                name = opts.name,
                            })
                            return
                        end
                    end

                    callback(HealthCheck.new {
                        result = "success",
                        version = version,
                        name = opts.name,
                    })
                else
                    callback(HealthCheck.new {
                        result = "not-available",
                        version = nil,
                        name = opts.name,
                    })
                end
            end)
        end
    end
end

function M.check()
    health.report_start "nvim-lsp-installer report"
    local completed = 0

    local check = mk_healthcheck(vim.schedule_wrap(
        ---@param healthcheck HealthCheck
        function(healthcheck)
            completed = completed + 1
            if healthcheck.result == "success" then
                -- We report on info level because we don't verify version compatibility yet
                health.report_info(("**%s**: `%s`"):format(healthcheck.name, healthcheck.version))
            elseif healthcheck.result == "version-mismatch" then
                health.report_warn(
                    ("**%s**: unsupported version `%s`. %s"):format(
                        healthcheck.name,
                        healthcheck.version,
                        healthcheck.reason
                    )
                )
            elseif healthcheck.result == "not-available" then
                health.report_error(("**%s**: not available"):format(healthcheck.name))
            end
        end
    ))

    local checks = Data.list_not_nil(
        check {
            cmd = "go",
            args = { "version" },
            name = "Go",
            check = function(version)
                -- Parses output such as "go version go1.17.3 darwin/arm64" into major, minor, patch components
                local _, _, major, minor = version:find "go(%d+)%.(%d+)%.(%d+)"
                -- Due to https://go.dev/doc/go-get-install-deprecation
                if not (tonumber(major) >= 1 and tonumber(minor) >= 17) then
                    return "Go version must be >= 1.17."
                end
            end,
        },
        check { cmd = "ruby", args = { "--version" }, name = "Ruby" },
        check { cmd = gem.gem_cmd, args = { "--version" }, name = "RubyGem" },
        check { cmd = composer.composer_cmd, args = { "--version" }, name = "Composer" },
        check { cmd = "php", args = { "--version" }, name = "PHP" },
        check {
            cmd = npm.npm_command,
            args = { "--version" },
            name = "npm",
            check = function(version)
                -- Parses output such as "8.1.2" into major, minor, patch components
                local _, _, major = version:find "(%d+)%.(%d+)%.(%d+)"
                -- Based off of general observations of feature parity
                if tonumber(major) < 6 then
                    return "npm version must be >= 6"
                end
            end,
        },
        check {
            cmd = "node",
            args = { "--version" },
            name = "node",
            check = function(version)
                -- Parses output such as "v16.3.1" into major, minor, patch
                local _, _, major = version:find "v(%d+)%.(%d+)%.(%d+)"
                if tonumber(major) < 14 then
                    return "Node version must be >= 14"
                end
            end,
        },
        when(platform.is_win, check { cmd = "python", use_stderr = true, args = { "--version" }, name = "python" }),
        when(platform.is_win, check { cmd = "python", args = { "-m", "pip", "--version" }, name = "pip" }),
        check { cmd = "python3", args = { "--version" }, name = "python3" },
        check { cmd = "python3", args = { "-m", "pip", "--version" }, name = "pip3" },
        check { cmd = "javac", args = { "-version" }, name = "java" },
        check { cmd = "wget", args = { "--version" }, name = "wget" },
        check { cmd = "curl", args = { "--version" }, name = "curl" },
        check {
            cmd = "gzip",
            args = { "--version" },
            name = "gzip",
            use_stderr = platform.is_mac, -- Apple gzip prints version string to stderr
        },
        check { cmd = "tar", args = { "--version" }, name = "tar" },
        when(
            vim.g.python3_host_prog,
            check { cmd = vim.g.python3_host_prog, args = { "--version" }, name = "python3_host_prog" }
        ),
        when(platform.is_unix, check { cmd = "bash", args = { "--version" }, name = "bash" }),
        when(platform.is_unix, check { cmd = "sh", args = { "--version" }, name = "sh" })
        -- when(platform.is_win, check { cmd = "powershell.exe", args = { "-Version" }, name = "PowerShell" }), -- TODO fix me
        -- when(platform.is_win, check { cmd = "cmd.exe", args = { "-Version" }, name = "cmd" }) -- TODO fix me
    )

    for _, c in ipairs(checks) do
        c()
    end

    vim.wait(5000, function()
        return completed >= #checks
    end, 50)
end

return M
