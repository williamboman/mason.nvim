local platform = require "nvim-lsp-installer.platform"
local log = require "nvim-lsp-installer.log"
local Data = require "nvim-lsp-installer.data"
local process = require "nvim-lsp-installer.process"
local fs = require "nvim-lsp-installer.fs"
local path = require "nvim-lsp-installer.path"

local M = {}

---@param installer ServerInstallerFunction[]|ServerInstallerFunction
---@return ServerInstallerFunction
local function normalize_installer(installer)
    if type(installer) == "table" then
        return M.pipe(installer)
    else
        return installer
    end
end

---@alias ServerInstallCallback fun(success: boolean)

---@class ServerInstallContext
---@field requested_server_version string|nil @The version requested by the user.
---@field stdio_sink StdioSink
---@field github_release_file string|nil @Only available if context.use_github_release_file has been called.
---@field install_dir string

---@alias ServerInstallerFunction fun(server: Server, callback: ServerInstallCallback, context: ServerInstallContext)

--- Composes multiple installer functions into one.
---@param installers ServerInstallerFunction[]
---@return ServerInstallerFunction
function M.pipe(installers)
    if #installers == 0 then
        error "No installers to pipe."
    end

    return function(server, callback, context)
        local function execute(idx)
            local ok, err = pcall(installers[idx], server, function(success)
                if not success then
                    -- oh no, error. exit early
                    callback(success)
                elseif installers[idx + 1] then
                    -- iterate
                    execute(idx + 1)
                else
                    -- we done
                    callback(success)
                end
            end, context)
            if not ok then
                context.stdio_sink.stderr(tostring(err) .. "\n")
                callback(false)
            end
        end

        execute(1)
    end
end

--- Composes multiple installer function into one - in reversed order.
---@param installers ServerInstallerFunction[]
function M.compose(installers)
    return M.pipe(Data.list_reverse(installers))
end

---@param installers ServerInstallerFunction[]
---@return ServerInstallerFunction @An installer function that will serially execute the provided installers, until the first one succeeds.
function M.first_successful(installers)
    if #installers == 0 then
        error "No installers to pipe."
    end

    return function(server, callback, context)
        local function execute(idx)
            log.fmt_trace("Executing installer idx=%d", idx)
            local ok, err = pcall(installers[idx], server, function(success)
                log.fmt_trace("Installer idx=%d on exit with success=%s", idx, success)
                if not success and installers[idx + 1] then
                    -- iterate
                    execute(idx + 1)
                else
                    callback(success)
                end
            end, context)
            if not ok then
                context.stdio_sink.stderr(tostring(err) .. "\n")
                if installers[idx + 1] then
                    execute(idx + 1)
                else
                    callback(false)
                end
            end
        end

        execute(1)
    end
end

--- Wraps the provided server installer to always succeeds.
---@param installer ServerInstallerFunction
---@return ServerInstallerFunction
function M.always_succeed(installer)
    return function(server, callback, context)
        installer(server, function()
            callback(true)
        end, context)
    end
end

---@param platform_table table<Platform, ServerInstallerFunction>
---@return ServerInstallerFunction | ServerInstallerFunction[] | nil
local function get_by_platform(platform_table)
    if platform.is_mac then
        return platform_table.mac or platform_table.unix
    elseif platform.is_linux then
        return platform_table.linux or platform_table.unix
    elseif platform.is_unix then
        return platform_table.unix
    elseif platform.is_win then
        return platform_table.win
    else
        return nil
    end
end

--- Creates a server installer that executes the given installer for the current platform.
--- If there is no server installer provided for the current platform, the installer will instantly exit successfully.
---@param platform_table table<Platform, ServerInstallerFunction>
---@return ServerInstallerFunction
function M.on(platform_table)
    return function(server, callback, context)
        local installer = get_by_platform(platform_table)
        if installer then
            normalize_installer(installer)(server, callback, context)
        else
            callback(true)
        end
    end
end

--- Creates a server installer that executes the given installer for the current platform.
--- If there is no server installer provided for the current platform, the installer will instantly exit with a failure.
---@param platform_table table<Platform, ServerInstallerFunction|ServerInstallerFunction[]>
---@return ServerInstallerFunction
function M.when(platform_table)
    return function(server, callback, context)
        local installer = get_by_platform(platform_table)
        if installer then
            normalize_installer(installer)(server, callback, context)
        else
            context.stdio_sink.stderr(
                ("Current operating system is not yet supported for server %q.\n"):format(server.name)
            )
            callback(false)
        end
    end
end

---@param installer ServerInstallerFunction|ServerInstallerFunction[] @The installer to execute in a new installer context.
function M.branch_context(installer)
    ---@type ServerInstallerFunction
    return function(server, callback, context)
        local new_context = vim.deepcopy(context)
        normalize_installer(installer)(server, callback, new_context)
    end
end

return M
