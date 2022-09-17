local _ = require "mason-core.functional"

local M = {}

local uname = vim.loop.os_uname()

---@alias Platform
---| '"win"'
---| '"unix"'
---| '"linux"'
---| '"mac"'

local arch_aliases = {
    ["x86_64"] = "x64",
    ["i386"] = "x86",
    ["i686"] = "x86", -- x86 compat
    ["aarch64"] = "arm64",
    ["aarch64_be"] = "arm64",
    ["armv8b"] = "arm64", -- arm64 compat
    ["armv8l"] = "arm64", -- arm64 compat
}

M.arch = arch_aliases[uname.machine] or uname.machine
M.sysname = uname.sysname

M.is_headless = #vim.api.nvim_list_uis() == 0

-- @return string @The libc found on the system, musl or glibc (glibc if ldd is not found)
local get_libc = _.lazy(function()
    local _, _, libc_exit_code = os.execute "ldd --version 2>&1 | grep -q musl"
    if libc_exit_code == 0 then
        return "musl"
    else
        return "glibc"
    end
end)

-- Most of the code that calls into these functions executes outside of the main event loop, where API/fn functions are
-- disabled. We evaluate these immediately here to avoid issues with main loop synchronization.
local cached_features = {
    ["win"] = vim.fn.has "win32",
    ["win32"] = vim.fn.has "win32",
    ["win64"] = vim.fn.has "win64",
    ["mac"] = vim.fn.has "mac",
    ["unix"] = vim.fn.has "unix",
    ["linux"] = vim.fn.has "linux",
}

---@type fun(env: string): boolean
local check_env = _.memoize(_.cond {
    {
        _.equals "musl",
        function()
            return get_libc() == "musl"
        end,
    },
    {
        _.equals "gnu",
        function()
            return get_libc() == "glibc"
        end,
    },
    { _.equals "openbsd", _.always(uname.sysname == "OpenBSD") },
    { _.T, _.F },
})

---Table that allows for checking whether the provided targets apply to the current system.
---Each key is a target tuple consisting of at most 3 targets, in the following order:
--- 1) OS (e.g. linux, unix, mac, win) - Mandatory
--- 2) Architecture (e.g. arm64, x64) - Optional
--- 3) Environment (e.g. gnu, musl, openbsd) - Optional
---Each target is separated by a "_" character, like so: "linux_x64_musl".
---@type table<string, boolean>
M.is = setmetatable({}, {
    __index = function(__, key)
        local os, arch, env = unpack(vim.split(key, "_", { plain = true }))
        if not cached_features[os] or cached_features[os] ~= 1 then
            return false
        end
        if arch and arch ~= M.arch then
            return false
        end
        if env and not check_env(env) then
            return false
        end
        return true
    end,
})

---@generic T
---@param platform_table table<Platform, T>
---@return T
local function get_by_platform(platform_table)
    if M.is.mac then
        return platform_table.mac or platform_table.unix
    elseif M.is.linux then
        return platform_table.linux or platform_table.unix
    elseif M.is.unix then
        return platform_table.unix
    elseif M.is.win then
        return platform_table.win
    else
        return nil
    end
end

function M.when(cases)
    local case = get_by_platform(cases)
    if case then
        return case()
    else
        error "Current platform is not supported."
    end
end

---@type async fun(): table
M.os_distribution = _.lazy(function()
    local Result = require "mason-core.result"

    ---Parses the provided contents of an /etc/\*-release file and identifies the Linux distribution.
    ---@param contents string The contents of a /etc/\*-release file.
    ---@return table<string, any>
    local function parse_linux_dist(contents)
        local lines = vim.split(contents, "\n")

        local entries = {}

        for i = 1, #lines do
            local line = lines[i]
            local index = line:find "="
            if index then
                local key = line:sub(1, index - 1)
                local value = line:sub(index + 1)
                entries[key] = value
            end
        end

        if entries.ID == "ubuntu" then
            -- Parses the Ubuntu OS VERSION_ID into their version components, e.g. "18.04" -> {major=18, minor=04}
            local version_id = entries.VERSION_ID:gsub([["]], "")
            local version_parts = vim.split(version_id, "%.")
            local major = tonumber(version_parts[1])
            local minor = tonumber(version_parts[2])

            return {
                id = "ubuntu",
                version_id = version_id,
                version = { major = major, minor = minor },
            }
        else
            return {
                id = "linux-generic",
            }
        end
    end

    return M.when {
        linux = function()
            local spawn = require "mason-core.spawn"
            return spawn
                .bash({ "-c", "cat /etc/*-release" })
                :map_catching(function(result)
                    return parse_linux_dist(result.stdout)
                end)
                :recover(function()
                    return { id = "linux-generic" }
                end)
                :get_or_throw()
        end,
        mac = function()
            return Result.success { id = "macOS" }
        end,
        win = function()
            return Result.success { id = "windows" }
        end,
    }
end)

---@type async fun(): Result<string>
M.get_homebrew_prefix = _.lazy(function()
    assert(M.is.mac, "Can only locate Homebrew installation on Mac systems.")
    local spawn = require "mason-core.spawn"
    return spawn
        .brew({ "--prefix" })
        :map_catching(function(result)
            return vim.trim(result.stdout)
        end)
        :map_err(function()
            return "Failed to locate Homebrew installation."
        end)
end)

---@async
function M.get_node_version()
    local spawn = require "mason-core.spawn"

    return spawn.node({ "--version" }):map(function(result)
        -- Parses output such as "v16.3.1" into major, minor, patch
        local _, _, major, minor, patch = _.head(_.split("\n", result.stdout)):find "v(%d+)%.(%d+)%.(%d+)"
        return { major = tonumber(major), minor = tonumber(minor), patch = tonumber(patch) }
    end)
end

-- PATH separator
M.path_sep = M.is.win and ";" or ":"

return M
