local functional = require "nvim-lsp-installer.core.functional"
local Result = require "nvim-lsp-installer.core.result"
local lazy = functional.lazy
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

M.is_win = vim.fn.has "win32" == 1
M.is_unix = vim.fn.has "unix" == 1
M.is_mac = vim.fn.has "mac" == 1
M.is_linux = not M.is_mac and M.is_unix

-- @return string @The libc found on the system, musl or glibc (glibc if ldd is not found)
function M.get_libc()
    local _, _, libc_exit_code = os.execute "ldd --version 2>&1 | grep -q musl"
    if libc_exit_code == 0 then
        return "musl"
    else
        return "glibc"
    end
end

-- PATH separator
M.path_sep = M.is_win and ";" or ":"

M.is_headless = #vim.api.nvim_list_uis() == 0

---@generic T
---@param platform_table table<Platform, T>
---@return T
local function get_by_platform(platform_table)
    if M.is_mac then
        return platform_table.mac or platform_table.unix
    elseif M.is_linux then
        return platform_table.linux or platform_table.unix
    elseif M.is_unix then
        return platform_table.unix
    elseif M.is_win then
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
M.os_distribution = lazy(function()
    ---Parses the provided contents of an /etc/\*-release file and identifies the Linux distribution.
    ---@param contents string @The contents of a /etc/\*-release file.
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
            local spawn = require "nvim-lsp-installer.core.spawn"
            return spawn.bash({ "-c", "cat /etc/*-release" })
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

---@type async fun() Result @of String
M.get_homebrew_prefix = lazy(function()
    assert(M.is_mac, "Can only locate Homebrew installation on Mac systems.")
    local spawn = require "nvim-lsp-installer.core.spawn"
    return spawn.brew({ "--prefix" })
        :map_catching(function(result)
            return vim.trim(result.stdout)
        end)
        :map_err(function()
            return "Failed to locate Homebrew installation."
        end)
end)

M.is = setmetatable({}, {
    __index = function(_, key)
        local platform, arch = unpack(vim.split(key, "_", { plain = true }))
        if arch and M.arch ~= arch then
            return false
        end
        return M["is_" .. platform] == true
    end,
})

return M
